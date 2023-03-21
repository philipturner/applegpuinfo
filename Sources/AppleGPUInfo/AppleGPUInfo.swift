import Metal
import IOKit

// Public API for the Swift file (feed this into GPT-4):
#if false

/// An error returned by the AppleGPUInfo library.
public class AppleGPUError: Error {
  /// Retrieve the description for this error.
  var description: String
  
  /// Initialize the error object.
  public init(description: String)
}

/// A data structure for querying parameters of an Apple-designed GPU.
public class AppleGPUDevice {
  /// Initialize the device object.
  public init() throws
}

public extension AppleGPUDevice {
  /// The full name of the GPU device.
  var name: String
  
  /// Number of GPU cores.
  var coreCount: Int
  
  /// Clock speed in Hz.
  ///
  /// Results should be cross-referenced with [philipturner/metal-benchmarks
  /// ](https://github.com/philipturner/metal-benchmarks).
  var clockFrequency: Double
  
  /// Maximum theoretical bandwidth to unified RAM, in bytes/second.
  var bandwidth: Double
  
  /// Maximum theoretical number of floating-point operations per second.
  ///
  /// This is a singular noun.
  var flops: Double
  
  /// Size of on-chip memory cache, in bytes.
  var systemLevelCache: Int
  
  /// Size of unified RAM, in bytes.
  var memory: Int
  
  /// Metal GPU family.
  var family: MTLGPUFamily
}
#endif

fileprivate func handleSysctlError(
  _ code: Int32,
  line: UInt = #line,
  file: StaticString = #file
) throws {
  guard code == 0 else {
    var message = "Encountered sysctl error code \(code)"
    message += " at \(file):\(line)"
    throw AppleGPUError(description: message)
  }
}

fileprivate func handleIORegistryError(
  _ code: Int32,
  line: UInt = #line,
  file: StaticString = #file
) throws {
  guard code == 0 else {
    var message = "Encountered IORegistry error code \(code)"
    message += " at \(file):\(line)"
    throw AppleGPUError(description: message)
  }
}

/// An error returned by the AppleGPUInfo library.
public class AppleGPUError: Error {
  /// Retrieve the description for this error.
  var description: String
  
  /// Initialize the error object.
  public init(description: String) {
    self.description = description
  }
}

/// A data structure for querying parameters of an Apple-designed GPU.
public class AppleGPUDevice {
  internal var mtlDevice: MTLDevice
  internal var gpuEntry: io_registry_entry_t
  
  // Cached values to decrease retrieval overhead.
  private var _name: String
  private var _coreCount: Int
  private var _clockFrequency: Double
  private var _bandwidth: Double
  private var _flops: Double
  private var _systemLevelCache: Int
  private var _memory: Int
  private var _family: MTLGPUFamily
  
  /// Initialize the device object.
  public init() throws {
    let devices = MTLCopyAllDevices()
    guard let appleDevice = devices.first(where: {
      $0.supportsFamily(.apple7 )
    }) else {
      throw AppleGPUError(description: "This device does is not an Apple GPU.")
    }
    self.mtlDevice = appleDevice
    
    // IOKit
    // Create a matching dictionary with "AGXAccelerator" class name
    let matchingDict = IOServiceMatching("AGXAccelerator")

    // Get an iterator for matching services
    var iterator: io_iterator_t = 0
    try handleIORegistryError(
      IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator))

    // Get the first (and only) GPU entry from the iterator
    self.gpuEntry = IOIteratorNext(iterator)

    // Check if the entry is valid
    if gpuEntry == MACH_PORT_NULL {
      throw AppleGPUError(
        description: "Error getting GPU entry at \(#file):\(#line - 5)")
    }

    // Release the iterator
    IOObjectRelease(iterator)
    
    // Cache the name.
    do {
      self._name = mtlDevice.name
    }
    
    // Cache the core count.
    do {
      // Get the "gpu-core-count" property from gpuEntry
      let key = "gpu-core-count"
      let options: IOOptionBits = 0 // No options needed
      let gpuCoreCount = IORegistryEntrySearchCFProperty(
        gpuEntry, kIOServicePlane, key as CFString, nil, options)

      // Check if the property is valid
      if gpuCoreCount == nil {
        throw AppleGPUError(description: """
          Error getting gpu-core-count property at \(#file):\(#line - 6)
          """)
      }

      // Cast the property to CFNumberRef
      let gpuCoreCountNumber = gpuCoreCount as! CFNumber

      // Check if the number type is sInt64
      let type = CFNumberGetType(gpuCoreCountNumber)
      if type != .sInt64Type {
        throw AppleGPUError(description: """
          Error: gpu-core-count is not sInt64 at \(#file):\(#line - 3)
          """)
      }

      // Get the value of the number as Int64
      var value: Int64 = 0
      let result = CFNumberGetValue(gpuCoreCountNumber, type, &value)

      // Check for errors
      if result == false {
        throw AppleGPUError(description: """
          Error getting value of gpu-core-count at \(#file):\(#line - 5)
          """)
      }
      
      self._coreCount = Int(value)
    }
    
    // Tier for calculating clock frequencies.
    enum Tier {
      case base
      case pro
      case max
      case ultra
      case unknown
    }
    
    // First, find the tier of the Metal GPU.
    var tier: Tier
    var name = mtlDevice.name
    name.removeFirst("Apple M".count)
    
    if name.allSatisfy(\.isWholeNumber) {
      tier = .base
    } else if name.contains("Pro") {
      tier = .pro
    } else if name.contains("Max") {
      tier = .max
    } else if name.contains("Ultra") {
      tier = .ultra
    } else {
      tier = .unknown
    }
    
    // Second, find the generation.
    var generationString = ""
    for character in name {
      if character.isWholeNumber {
        generationString.append(character)
      } else {
        break
      }
    }
    guard let generation = Int(generationString) else {
      throw AppleGPUError(description: """
        Could not transform string '\(generationString)' extracted from \
        '\(name)' into a number.
        """)
    }
    
    // Cache the clock frequency.
    do {
      switch generation {
      case 1:
        switch tier {
        case .base: _clockFrequency = 1.278e9
        case .pro, .max, .ultra: _clockFrequency = 1.296e9
        case .unknown: _clockFrequency = 1.296e9
        }
      case 2:
        fallthrough
      default:
        switch tier {
        case .base: _clockFrequency = 1.398e9
        case .pro, .max: _clockFrequency = 1.398e9
        default: _clockFrequency = 1.398e9
        }
      }
    }
    
    // Cache the bandwidth.
    do {
      // clock: bits/second per LPDDR pin
      // bits: size of memory interface
      func dataRate(clock: Double, bits: Int) -> Double {
        return clock * Double(bits / 8)
      }
      
      switch generation {
      case 1:
        switch tier {
        case .base: _bandwidth = dataRate(clock: 4.266e9, bits: 128)
        case .pro: _bandwidth = dataRate(clock: 6.400e9, bits: 256)
        case .max: _bandwidth = dataRate(clock: 6.400e9, bits: 512)
        case .ultra: _bandwidth = dataRate(clock: 6.400e9, bits: 1024)
        case .unknown: _bandwidth = dataRate(clock: 6.400e9, bits: 1024)
        }
      case 2:
        fallthrough
      default:
        switch tier {
        case .base: _bandwidth = dataRate(clock: 6.400e9, bits: 128)
        case .pro: _bandwidth = dataRate(clock: 6.400e9, bits: 256)
        case .max: _bandwidth = dataRate(clock: 6.400e9, bits: 512)
        case .ultra: _bandwidth = dataRate(clock: 6.400e9, bits: 1024)
        case .unknown: _bandwidth = dataRate(clock: 6.400e9, bits: 1024)
        }
      }
    }
    
    // Cache the FLOPS.
    do {
      let operationsPerClock = self._coreCount * 128 * 2
      self._flops = Double(operationsPerClock) * _clockFrequency
    }
    
    // Cache the system-level cache.
    do {
      let megabyte = 1024 * 1024
      
      switch generation {
      case 1:
        switch tier {
        case .base: _systemLevelCache = 8 * megabyte
        case .pro: _systemLevelCache = 24 * megabyte
        case .max: _systemLevelCache = 48 * megabyte
        case .ultra: _systemLevelCache = 96 * megabyte
        case .unknown: _systemLevelCache = 96 * megabyte
        }
      case 2:
        fallthrough
      default:
        switch tier {
        case .base: _systemLevelCache = 8 * megabyte
        case .pro: _systemLevelCache = 24 * megabyte
        case .max: _systemLevelCache = 48 * megabyte
        case .ultra: _systemLevelCache = 96 * megabyte
        case .unknown: _systemLevelCache = 96 * megabyte
        }
      }
    }
    
    // Cache the memory.
    do {
      var memorySize: Int = 0
      var sizeOfInt: Int = 8
      do {
        try handleSysctlError(
          sysctlbyname("hw.memsize", &memorySize, &sizeOfInt, nil, 0))
      } catch {
        fatalError(error.localizedDescription)
      }
      self._memory = memorySize
    }
    
    // Cache the family.
    do {
      // TODO: Recognize more than just Apple 7/8 when porting to iOS.
      var maxRecognized: MTLGPUFamily = .apple8
      while maxRecognized.rawValue >= 0 {
        if mtlDevice.supportsFamily(maxRecognized) {
          break
        } else {
          maxRecognized = .init(rawValue: maxRecognized.rawValue - 1)!
        }
      }
      self._family = maxRecognized
    }
  }
}

public extension AppleGPUDevice {
  /// The full name of the GPU device.
  var name: String {
    return _name
  }
  
  /// Number of GPU cores.
  var coreCount: Int {
    return _coreCount
  }
  
  /// Clock speed in Hz.
  ///
  /// Results should be cross-referenced with [philipturner/metal-benchmarks
  /// ](https://github.com/philipturner/metal-benchmarks).
  var clockFrequency: Double {
    return _clockFrequency
  }
  
  /// Maximum theoretical bandwidth to unified RAM, in bytes/second.
  var bandwidth: Double {
    return _bandwidth
  }
  
  /// Maximum theoretical number of floating-point operations per second.
  ///
  /// This is a singular noun.
  var flops: Double {
    return _flops
  }
  
  /// Size of on-chip memory cache, in bytes.
  var systemLevelCache: Int {
    return _systemLevelCache
  }
  
  /// Size of unified RAM, in bytes.
  var memory: Int {
    return _memory
  }
  
  /// Metal GPU family.
  var family: MTLGPUFamily {
    return _family
  }
}

// C API - exported symbols loadable from the dylib.
// TODO: Make tests for this, finish bindings the AppleGPUDevice object.

@_cdecl("AppleGPUError_init")
@usableFromInline
internal func AppleGPUError_init(
  _ description: UnsafePointer<CChar>
) -> UnsafeMutableRawPointer {
  // Create a Swift class object
  let error = AppleGPUError(
    description: String(cString: description, encoding: .utf8)!)

  // Convert it to an unsafe reference with +1 retain count
  let unmanagedError = Unmanaged.passRetained(error)

  // Get an UnsafeMutablePointer from unmanagedError
  return unmanagedError.toOpaque()
}

@_cdecl("AppleGPUError_deinit")
@usableFromInline
internal func AppleGPUError_deinit(
  _ pointerError: UnsafeMutableRawPointer
) {
  // Get an unmanaged reference from pointerError
  let unmanagedError = Unmanaged<AppleGPUError>.fromOpaque(pointerError)
  
  // Release the object referenced by pointerError
  unmanagedError.release()
}

@_cdecl("AppleGPUError_description")
@usableFromInline
internal func AppleGPUError_description(
  _ pointerError: UnsafeMutableRawPointer
) -> UnsafePointer<CChar> {
  // Get an unmanaged reference from pointerError
  let unmanagedError = Unmanaged<AppleGPUError>.fromOpaque(pointerError)
  
  // Get a Swift class reference to unmanagedError
  let error = unmanagedError.takeUnretainedValue()
  
  return error.description.withCString { $0 }
}

//#if false
//// Initialize the device object.
//AppleGPUDevice *AppleGPUDevice_init(AppleGPUError *error);
//
//// Free the device object.
//void AppleGPUDevice_free(AppleGPUDevice *device);
//
//// The full name of the GPU device.
//const char *AppleGPUDevice_name(AppleGPUDevice *device);
//
//// Number of GPU cores.
//int AppleGPUDevice_coreCount(AppleGPUDevice *device);
//
//// Clock speed in Hz.
//double AppleGPUDevice_clockFrequency(AppleGPUDevice *device);
//
//// Maximum theoretical bandwidth to unified RAM, in bytes/second.
//double AppleGPUDevice_bandwidth(AppleGPUDevice *device);
//
//// Maximum theoretical number of floating-point operations per second.
//double AppleGPUDevice_flops(AppleGPUDevice *device);
//
//// Size of on-chip memory cache, in bytes.
//int AppleGPUDevice_systemLevelCache(AppleGPUDevice *device);
//
//// Size of unified RAM, in bytes.
//int AppleGPUDevice_memory(AppleGPUDevice *device);
//
//// Metal GPU family (as an integer).
//int AppleGPUDevice_family(AppleGPUDevice *device);
//#endif
