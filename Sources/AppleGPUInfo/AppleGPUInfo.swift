import Metal
#if os(macOS)
import IOKit
#else
import DeviceKit
#endif

// Public API for the Swift file (feed this into GPT-4):
#if false

/// An error returned by the AppleGPUInfo library.
public class AppleGPUError: Error {
  /// Retrieve the description for this error.
  public var description: String
  
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
  /// The number of FP32 operations performed through fused muliply-add each
  /// second. This is a singular noun.
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
  public let description: String
  
  /// For compatibility with the C API, store an explicit C string.
  internal let _cDescripton: UnsafeMutablePointer<CChar>
  
  /// Initialize the error object.
  public init(description: String) {
    self.description = description
    self._cDescripton = .allocate(capacity: description.count)
    strcpy(_cDescripton, description)
  }
  
  deinit {
    _cDescripton.deallocate()
  }
}

/// A data structure for querying parameters of an Apple-designed GPU.
public class AppleGPUDevice {
  internal let mtlDevice: MTLDevice
  #if os(macOS)
  internal let gpuEntry: io_registry_entry_t
  #else
  internal let deviceKitDevice: Device
  #endif
  
  // Cached values to decrease retrieval overhead.
  private let _name: String
  private let _coreCount: Int
  private let _clockFrequency: Double
  private let _bandwidth: Double
  private let _flops: Double
  private let _systemLevelCache: Int
  private let _memory: Int
  private let _family: MTLGPUFamily
  
  /// For compatibility with the C API, store an explicit C string.
  internal let _cName: UnsafeMutablePointer<CChar>
  
  /// Initialize the device object.
  public init() throws {
    #if os(macOS)
    let devices = MTLCopyAllDevices()
    guard let appleDevice = devices.first(where: {
      $0.supportsFamily(.apple2)
    }) else {
      throw AppleGPUError(description: "This device does is not an Apple GPU.")
    }
    self.mtlDevice = appleDevice
    #else
    self.mtlDevice = MTLCreateSystemDefaultDevice()!
    #endif
    
    // Cache the name.
    do {
      self._name = mtlDevice.name
      self._cName = .allocate(capacity: _name.count)
      strcpy(_cName, _name)
    }
    
    #if os(macOS)
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
    #else
    self.deviceKitDevice = Device.current
    #endif
    
    // Tier for calculating clock frequencies and other statistics.
    enum Tier {
      case phone
      case base
      case pro
      case max
      case ultra
      case unknown
    }
    
    // First, find the tier of the Metal GPU.
    var tier: Tier
    var name = mtlDevice.name
    if name.starts(with: "Apple A") {
      name.removeFirst("Apple A".count)
      
      if name.last!.isWholeNumber == true {
        // A12, etc.
        tier = .phone
      } else {
        // A12X, A12Z, etc.
        tier = .base
      }
    } else {
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
    
    // Cache the core count.
    do {
      #if os(macOS)
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
      #else
      if name.starts(with: "Apple A") {
        switch generation {
        case 8:
          self._coreCount = 4
        case 9:
          fallthrough
        case 10:
          switch tier {
          case .phone: _coreCount = 6
          case .base: _coreCount = 12
          default: throw AppleGPUError(description: """
            Unrecognized GPU: \(name)
            """)
          }
        case 11:
          self._coreCount = 3
        case 12:
          switch tier {
          case .phone: _coreCount = 4
          case .base: _coreCount = name.contains("Z") ? 8 : 7
          default: throw AppleGPUError(description: """
            Unrecognized GPU: \(name)
            """)
          }
        case 13:
          fallthrough
        case 14:
          self._coreCount = 4
        case 15:
          // Need DeviceKit to distinguish iPhone 13 from 13 Pro
          switch deviceKitDevice {
          case .iPhone13Mini:
            fallthrough
          case .iPhone13:
            fallthrough
          case .iPhoneSE3:
            self._coreCount = 4
          default:
            self._coreCount = 5
          }
        case 16:
          fallthrough
        default:
          self._coreCount = 5
        }
      } else {
        switch generation {
        case 1:
          self._coreCount = 8
        case 2:
          fallthrough
        default:
          self._coreCount = 10
        }
      }
      #endif
    }
    
    // Cache the clock frequency.
    do {
      if name.contains("Apple A") {
        // TODO: Support iOS.
        _clockFrequency = 0
      } else {
        switch generation {
        case 1:
          switch tier {
          case .phone: throw AppleGPUError(description: """
            Unrecognized GPU: \(name)
            """)
          case .base: _clockFrequency = 1.278e9
          case .pro, .max, .ultra: _clockFrequency = 1.296e9
          case .unknown: _clockFrequency = 1.296e9
          }
        case 2:
          fallthrough
        default:
          switch tier {
          case .phone: throw AppleGPUError(description: """
            Unrecognized GPU: \(name)
            """)
          case .base: _clockFrequency = 1.398e9
          case .pro, .max: _clockFrequency = 1.398e9
          default: _clockFrequency = 1.398e9
          }
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
      
      if name.contains("Apple A") {
        // TODO: Support iOS.
        _bandwidth = 0
      } else {
        switch generation {
        case 1:
          switch tier {
          case .phone: throw AppleGPUError(description: """
            Unrecognized GPU: \(name)
            """)
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
          case .phone: throw AppleGPUError(description: """
            Unrecognized GPU: \(name)
            """)
          case .base: _bandwidth = dataRate(clock: 6.400e9, bits: 128)
          case .pro: _bandwidth = dataRate(clock: 6.400e9, bits: 256)
          case .max: _bandwidth = dataRate(clock: 6.400e9, bits: 512)
          case .ultra: _bandwidth = dataRate(clock: 6.400e9, bits: 1024)
          case .unknown: _bandwidth = dataRate(clock: 6.400e9, bits: 1024)
          }
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
      
      if name.contains("Apple A") {
        // TODO: Support iOS.
        _systemLevelCache = 0
      } else {
        switch generation {
        case 1:
          switch tier {
          case .phone: throw AppleGPUError(description: """
            Unrecognized GPU: \(name)
            """)
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
          case .phone: throw AppleGPUError(description: """
            Unrecognized GPU: \(name)
            """)
          case .base: _systemLevelCache = 8 * megabyte
          case .pro: _systemLevelCache = 24 * megabyte
          case .max: _systemLevelCache = 48 * megabyte
          case .ultra: _systemLevelCache = 96 * megabyte
          case .unknown: _systemLevelCache = 96 * megabyte
          }
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
  
  deinit {
    #if os(macOS)
    IOObjectRelease(gpuEntry)
    #endif
    _cName.deallocate()
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
  /// The number of FP32 operations performed through fused muliply-add each
  /// second. This is a singular noun.
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
// TODO: Make a test script that loads the dylib object.

/// Initialize the error object.
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

/// Deinitialize the error object.
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

/// The description of the error.
@_cdecl("AppleGPUError_description")
@usableFromInline
internal func AppleGPUError_description(
  _ pointerError: UnsafeMutableRawPointer
) -> UnsafePointer<CChar> {
  // Get an unmanaged reference from pointerError
  let unmanagedError = Unmanaged<AppleGPUError>.fromOpaque(pointerError)
  
  // Get a Swift class reference to unmanagedError
  let error = unmanagedError.takeUnretainedValue()
  
  // Return C-accessible copy of string contents
  return UnsafePointer(error._cDescripton)
}

/// Initialize the device object, returning any errors at +1 refcount.
@_cdecl("AppleGPUDevice_init")
@usableFromInline
internal func AppleGPUDevice_init(
  _ pointerError: UnsafeMutablePointer<UnsafeMutableRawPointer?>
) -> UnsafeMutableRawPointer? {
  var device: AppleGPUDevice
  
  do {
    // Create a Swift class object
    device = try AppleGPUDevice()
  } catch let error as AppleGPUError {
    // Convert the error to an unsafe reference with +1 retain count
    let unmanagedError = Unmanaged.passRetained(error)

    // Get an UnsafeMutablePointer from unmanagedError
    pointerError.pointee = unmanagedError.toOpaque()
    
    // Return early.
    return nil
  } catch {
    fatalError("This should never happen!")
  }

  // Convert it to an unsafe reference with +1 retain count
  let unmanagedDevice = Unmanaged.passRetained(device)

  // Get an UnsafeMutablePointer from unmanagedDevice
  return unmanagedDevice.toOpaque()
}

/// Deinitialize the device object.
@_cdecl("AppleGPUDevice_deinit")
@usableFromInline
internal func AppleGPUDevice_deinit(
  _ pointerDevice: UnsafeMutableRawPointer
) {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<AppleGPUError>.fromOpaque(pointerDevice)
  
  // Release the object referenced by pointerDevice
  unmanagedDevice.release()
}

/// The full name of the GPU device.
@_cdecl("AppleGPUDevice_name")
@usableFromInline
internal func AppleGPUDevice_name(
  _ pointerDevice: UnsafeMutableRawPointer
) -> UnsafePointer<CChar> {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<AppleGPUDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return C-accessible copy of string contents
  return UnsafePointer(device._cName)
}

/// Number of GPU cores.
@_cdecl("AppleGPUDevice_coreCount")
@usableFromInline
internal func AppleGPUDevice_coreCount(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Int64 {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<AppleGPUDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the core count.
  return Int64(device.coreCount)
}

/// Clock speed in Hz.
@_cdecl("AppleGPUDevice_clockFrequency")
@usableFromInline
internal func AppleGPUDevice_clockFrequency(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Double {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<AppleGPUDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the clock frequency.
  return Double(device.clockFrequency)
}

/// Maximum theoretical bandwidth to unified RAM, in bytes/second.
@_cdecl("AppleGPUDevice_bandwidth")
@usableFromInline
internal func AppleGPUDevice_bandwidth(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Double {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<AppleGPUDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the bandwidth.
  return Double(device.bandwidth)
}

/// Maximum theoretical number of floating-point operations per second.
@_cdecl("AppleGPUDevice_flops")
@usableFromInline
internal func AppleGPUDevice_flops(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Double {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<AppleGPUDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the FLOPS.
  return Double(device.flops)
}

/// Size of on-chip memory cache, in bytes.
@_cdecl("AppleGPUDevice_systemLevelCache")
@usableFromInline
internal func AppleGPUDevice_systemLevelCache(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Int64 {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<AppleGPUDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the system level cache.
  return Int64(device.systemLevelCache)
}

/// Size of unified RAM, in bytes.
@_cdecl("AppleGPUDevice_memory")
@usableFromInline
internal func AppleGPUDevice_memory(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Int64 {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<AppleGPUDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the system level cache.
  return Int64(device.memory)
}

/// Metal GPU family (as an integer).
@_cdecl("AppleGPUDevice_family")
@usableFromInline
internal func AppleGPUDevice_family(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Int64 {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<AppleGPUDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the system level cache.
  return Int64(device.family.rawValue)
}
