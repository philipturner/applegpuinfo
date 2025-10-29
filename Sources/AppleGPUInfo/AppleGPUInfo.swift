import Metal
#if os(macOS)
import IOKit
#else
import DeviceKit
#endif

/// An error returned by the AppleGPUInfo library.
public class GPUInfoError: Error {
  /// The description of the error.
  public let description: String
  
  /// For compatibility with the C API, store an explicit C string.
  internal let _cDescripton: UnsafeMutablePointer<CChar>
  
  /// Initialize the error object.
  public init(description: String) {
    self.description = description
    self._cDescripton = .allocate(capacity: description.count + 1)
    strcpy(_cDescripton, description)
  }
  
  /// Deinitialize the error object.
  deinit {
    _cDescripton.deallocate()
  }
}

public extension GPUInfoDevice {
  /// The full name of the GPU device.
  var name: String {
    return _name
  }
  
  /// The manufacturer of the GPU device.
  var vendor: String {
    return _vendor
  }
  
  /// The number of GPU cores.
  var coreCount: Int {
    return _coreCount
  }
  
  /// The clock speed in Hz.
  ///
  /// Results should be cross-referenced with
  /// [philipturner/metal-benchmarks](https://github.com/philipturner/metal-benchmarks).
  var clockFrequency: Double {
    return _clockFrequency
  }
  
  /// The maximum theoretical bandwidth to random-access memory, in
  /// bytes/second.
  var bandwidth: Double {
    return _bandwidth
  }
  
  /// The maximum theoretical number of floating-point operations per second.
  ///
  /// The number of `Float32` operations performed each second through fused
  /// multiply-add.
  var flops: Double {
    return _flops
  }
  
  /// The maximum theoretical number of shader instructions per second.
  ///
  /// The number of `Int32` add operations performed each second. See the
  /// [Apple GPU ISA](https://github.com/dougallj/applegpu) for situations
  /// where multiple operations are fused into one shader instruction.
  var ips: Double {
    return _ips
  }
  
  /// The size of the on-chip memory cache, in bytes.
  ///
  /// This property sometimes returns zero. If your application targets iPads
  /// with the A9X or A10X chip, provide fallbacks for optimizations that
  /// require a nonzero cache size.
  var systemLevelCache: Int {
    return _systemLevelCache
  }
  
  /// The size of the device's random-access memory, in bytes.
  var memory: Int {
    return _memory
  }
  
  /// The Metal GPU family.
  var family: MTLGPUFamily {
    return _family
  }
}

/// An object for querying parameters of an Apple-designed GPU.
public class GPUInfoDevice {
  // Objects for querying parameters.
  internal let mtlDevice: MTLDevice
#if os(macOS)
  internal let gpuEntry: io_registry_entry_t
#else
  internal let deviceKitDevice: Device
#endif
  
  // Cached values to decrease retrieval overhead.
  private let _name: String
  private let _vendor: String
  private let _coreCount: Int
  private let _clockFrequency: Double
  private let _bandwidth: Double
  private let _flops: Double
  private let _ips: Double
  private let _systemLevelCache: Int
  private let _memory: Int
  private let _family: MTLGPUFamily
  
  /// For compatibility with the C API, store an explicit C string.
  internal let _cName: UnsafeMutablePointer<CChar>
  internal let _cVendor: UnsafeMutablePointer<CChar>
  
  /// Initialize the device object.
  ///
  /// Creating a `GPUInfoDevice` is a costly operation. If possible, create one
  /// object and use it multiple times.
  public init() throws {
#if os(macOS)
    let devices = MTLCopyAllDevices()
    guard let selectedDevice = devices.first else {
      fatalError("No devices are available.")
    }
    self.mtlDevice = selectedDevice
#else
    self.mtlDevice = MTLCreateSystemDefaultDevice()!
#endif
    
    // Cache the name.
    do {
      self._name = mtlDevice.name
      self._cName = .allocate(capacity: _name.count + 1)
      strcpy(_cName, _name)
    }
    
    // Cache the vendor.
    do {
      self._vendor = "Apple"
      self._cVendor = .allocate(capacity: _vendor.count + 1)
      strcpy(_cVendor, _vendor)
    }
    
#if os(macOS)
    // Create a matching dictionary with "AGXAccelerator" class name
    let matchingDict = IOServiceMatching("AGXAccelerator")
    
    // Get an iterator for matching services
    var iterator: io_iterator_t = 0
    do {
      let io_registry_error =
      IOServiceGetMatchingServices(
        kIOMainPortDefault, matchingDict, &iterator)
      guard io_registry_error == 0 else {
        throw GPUInfoError(description: """
        Encountered IORegistry error code \(io_registry_error)
        """)
      }
    }
    
    // Get the first (and only) GPU entry from the iterator
    self.gpuEntry = IOIteratorNext(iterator)
    
    // Check if the entry is valid
    if gpuEntry == MACH_PORT_NULL {
      throw GPUInfoError(
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
      
      if name.count >= 4, name.suffix(4) == " Pro" {
        name.removeLast(4)
      }
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
      throw GPUInfoError(description: """
        Could not transform string '\(generationString)' extracted from \
        '\(name)' into a number.
        """)
    }
    
    // Reset the `name` variable.
    name = mtlDevice.name
    
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
        throw GPUInfoError(description: """
          Error getting gpu-core-count property at \(#file):\(#line - 6)
          """)
      }
      
      // Cast the property to CFNumberRef
      let gpuCoreCountNumber = gpuCoreCount as! CFNumber
      
      // Check if the number type is sInt64
      let type = CFNumberGetType(gpuCoreCountNumber)
      if type != .sInt64Type {
        throw GPUInfoError(description: """
          Error: gpu-core-count is not sInt64 at \(#file):\(#line - 3)
          """)
      }
      
      // Get the value of the number as Int64
      var value: Int64 = 0
      let result = CFNumberGetValue(gpuCoreCountNumber, type, &value)
      
      // Check for errors
      if result == false {
        throw GPUInfoError(description: """
          Error getting value of gpu-core-count at \(#file):\(#line - 5)
          """)
      }
      
      self._coreCount = Int(value)
#else
      if name.starts(with: "Apple A") {
        switch generation {
        case 7: fallthrough
        case 8: _coreCount = 4
        case 9: fallthrough
        case 10:
          switch tier {
          case .phone: _coreCount = 6
          case .base: _coreCount = 12
          default: throw GPUInfoError(description: """
            Unrecognized GPU: \(name)
            """)
          }
        case 11: _coreCount = 3
        case 12:
          switch tier {
          case .phone: _coreCount = 4
          case .base: _coreCount = name.contains("Z") ? 8 : 7
          default: throw GPUInfoError(description: """
            Unrecognized GPU: \(name)
            """)
          }
        case 13: fallthrough
        case 14: _coreCount = 4
        case 15:
          // Need DeviceKit to distinguish iPhone 13 from 13 Pro.
          switch deviceKitDevice {
          case .iPhone13Mini: fallthrough
          case .iPhone13: fallthrough
          case .iPhoneSE3: _coreCount = 4
          default: _coreCount = 5
          }
        case 16: _coreCount = 5
        case 17: _coreCount = 6
        default: _coreCount = 6
        }
      } else {
        switch generation {
        case 1: _coreCount = 8
        case 2: fallthrough
        default: _coreCount = 10
        }
      }
#endif
    }
    
    // Cache the clock frequency.
    do {
      if name.contains("Apple A") {
        switch generation {
        case 7: _clockFrequency = 0.450e9
        case 8: _clockFrequency = 0.533e9
        case 9: _clockFrequency = 0.650e9
        case 10:
          if name.contains("X") {
            // A10X
            _clockFrequency = 1.000e9
          } else {
            // A10
            _clockFrequency = 0.900e9
          }
        case 11: _clockFrequency = 1.066e9
        case 12: _clockFrequency = 1.128e9
        case 13: _clockFrequency = 1.230e9
        case 14: _clockFrequency = 1.278e9
        case 15: _clockFrequency = 1.338e9
        case 16: _clockFrequency = 1.398e9
        case 17: _clockFrequency = 1.380e9
        default: _clockFrequency = 1.380e9
        }
      } else {
        switch generation {
        case 1:
          switch tier {
          case .phone: throw GPUInfoError(description: """
            Unrecognized GPU: \(name)
            """)
          case .base: _clockFrequency = 1.278e9
          case .pro, .max, .ultra: _clockFrequency = 1.296e9
          case .unknown: _clockFrequency = 1.296e9
          }
        case 2: _clockFrequency = 1.398e9
        case 3: _clockFrequency = 1.380e9
        default: _clockFrequency = 1.380e9
        }
      }
    }
    
    // Cache the bandwidth.
    do {
      // clock: 0.5 * bits/second per LPDDR pin
      // bits: number of pins in memory interface
      func dataRate(clock: Double, bits: Int) -> Double {
        return 2 * clock * Double(bits / 8)
      }
      
      if name.contains("Apple A") {
        switch generation {
        case 7: fallthrough
        case 8:
          if name.contains("X") {
            // A8X
            _bandwidth = dataRate(clock: 0.800e9, bits: 128)
          } else {
            // A8
            _bandwidth = dataRate(clock: 0.800e9, bits: 64)
          }
        case 9: fallthrough
        case 10:
          if name.contains("X") {
            // A9X, A10X
            _bandwidth = dataRate(clock: 1.600e9, bits: 128)
          } else {
            // A9, A10
            _bandwidth = dataRate(clock: 1.600e9, bits: 64)
          }
        case 11: fallthrough
        case 12: fallthrough
        case 13: fallthrough
        case 14: fallthrough
        case 15:
          if name.contains("X") || name.contains("Z") {
            // A12X, A12Z
            _bandwidth = dataRate(clock: 2.133e9, bits: 128)
          } else {
            // A12
            _bandwidth = dataRate(clock: 2.133e9, bits: 64)
          }
        case 16: fallthrough
        case 17: fallthrough
        default: _bandwidth = dataRate(clock: 3.200e9, bits: 64)
        }
      } else {
        switch generation {
        case 1:
          switch tier {
          case .phone: throw GPUInfoError(description: """
            Unrecognized GPU: \(name)
            """)
          case .base: _bandwidth = dataRate(clock: 2.133e9, bits: 128)
          case .pro: _bandwidth = dataRate(clock: 3.200e9, bits: 256)
          case .max: _bandwidth = dataRate(clock: 3.200e9, bits: 512)
          case .ultra: _bandwidth = dataRate(clock: 3.200e9, bits: 1024)
          case .unknown: _bandwidth = dataRate(clock: 3.200e9, bits: 1024)
          }
        case 2:
          switch tier {
          case .phone: throw GPUInfoError(description: """
            Unrecognized GPU: \(name)
            """)
          case .base: _bandwidth = dataRate(clock: 3.200e9, bits: 128)
          case .pro: _bandwidth = dataRate(clock: 3.200e9, bits: 256)
          case .max: _bandwidth = dataRate(clock: 3.200e9, bits: 512)
          case .ultra: _bandwidth = dataRate(clock: 3.200e9, bits: 1024)
          case .unknown: _bandwidth = dataRate(clock: 3.200e9, bits: 1024)
          }
        case 3:
          switch tier {
          case .phone: throw GPUInfoError(description: """
            Unrecognized GPU: \(name)
            """)
          case .base: _bandwidth = dataRate(clock: 3.200e9, bits: 128)
          case .pro: _bandwidth = dataRate(clock: 3.200e9, bits: 192)
          case .max:
            if _coreCount < 40 {
              _bandwidth = dataRate(clock: 3.200e9, bits: 384)
            } else {
              _bandwidth = dataRate(clock: 3.200e9, bits: 512)
            }
          case .ultra: _bandwidth = dataRate(clock: 3.200e9, bits: 1024)
          case .unknown: _bandwidth = dataRate(clock: 3.200e9, bits: 1024)
          }
        case 4:
          // M4 generation uses LPDDR5X-8533 memory
          switch tier {
          case .phone: throw GPUInfoError(description: """
            Unrecognized GPU: \(name)
            """)
          case .base: _bandwidth = dataRate(clock: 4.266e9, bits: 128)
          case .pro: _bandwidth = dataRate(clock: 4.266e9, bits: 256)
          case .max: _bandwidth = dataRate(clock: 4.266e9, bits: 512)
          case .ultra: _bandwidth = dataRate(clock: 4.266e9, bits: 1024)
          case .unknown: _bandwidth = dataRate(clock: 4.266e9, bits: 1024)
          }
        default:
          switch tier {
          case .phone: throw GPUInfoError(description: """
            Unrecognized GPU: \(name)
            """)
          case .base: _bandwidth = dataRate(clock: 4.266e9, bits: 128)
          case .pro: _bandwidth = dataRate(clock: 4.266e9, bits: 256)
          case .max: _bandwidth = dataRate(clock: 4.266e9, bits: 512)
          case .ultra: _bandwidth = dataRate(clock: 4.266e9, bits: 1024)
          case .unknown: _bandwidth = dataRate(clock: 4.266e9, bits: 1024)
          }
        }
      }
    }
    
    // Cache the FLOPS.
    do {
      // Number of FP32 ALUs per GPU core.
      var alusPerCore: Int
      
      if name.contains("Apple A") {
        if generation >= 15 {
          alusPerCore = 128
        } else if generation >= 11 {
          alusPerCore = 64
        } else {
          alusPerCore = 32
        }
      } else if name.contains("Apple M") {
        alusPerCore = 128
      } else {
        fatalError("Unrecognized name.")
      }
      
      // Two floating-point operations per FMA.
      let fmaMultiplier = 2
      let operationsPerClock = self._coreCount * alusPerCore * fmaMultiplier
      self._flops = Double(operationsPerClock) * _clockFrequency
    }
    
    // Cache the instructions per second.
    do {
      // Number of ALUs that can be simultaneously utilized.
      var alusPerCore: Int
      
      // Make a rough prediction that Apple9 GPUs can utilize two pipelines
      // simultaneously, but not all three.
      if name.contains("Apple A") {
        if generation >= 17 {
          alusPerCore = 256
        } else if generation >= 11 {
          alusPerCore = 128
        } else {
          alusPerCore = 64
        }
      } else if name.contains("Apple M") {
        if generation >= 3 {
          alusPerCore = 256
        } else {
          alusPerCore = 128
        }
      } else {
        fatalError("Unrecognized name.")
      }
      
      let operationsPerClock = Double(self._coreCount * alusPerCore)
      self._ips = operationsPerClock * _clockFrequency
    }
    
    // Cache the system-level cache.
    do {
      let megabyte = 1024 * 1024
      
      if name.contains("Apple A") {
        switch generation {
        case 7: _systemLevelCache = 4 * megabyte
        case 8: _systemLevelCache = 4 * megabyte
        case 9: fallthrough
        case 10:
          if name.contains("X") {
            // A9X, A10X
            _systemLevelCache = 0
          } else {
            // A9, A11
            _systemLevelCache = 4 * megabyte
          }
        case 11: _systemLevelCache = 4 * megabyte
        case 12: _systemLevelCache = 8 * megabyte
        case 13: _systemLevelCache = 16 * megabyte
        case 14: _systemLevelCache = 16 * megabyte
        case 15: _systemLevelCache = 32 * megabyte
        default: _systemLevelCache = 24 * megabyte
        }
      } else {
        switch tier {
        case .phone: throw GPUInfoError(description: """
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
    
    // Cache the memory.
    do {
      var memorySize: Int = 0
      var sizeOfInt: Int = 8
      do {
        let sysctl_error =
        sysctlbyname("hw.memsize", &memorySize, &sizeOfInt, nil, 0)
        guard sysctl_error == 0 else {
          throw GPUInfoError(description: """
            Encountered sysctl error code \(sysctl_error)
            """)
        }
      } catch {
        fatalError(error.localizedDescription)
      }
      self._memory = memorySize
    }
    
    // Cache the family.
    do {
      // Apple 9 (1000 + 9)
      var maxRecognized: MTLGPUFamily = .init(rawValue: 1009)!
      while maxRecognized.rawValue >= 0 {
        if mtlDevice.supportsFamily(maxRecognized) {
          break
        } else {
          maxRecognized = .init(rawValue: maxRecognized.rawValue - 1)!
        }
      }
      self._family = maxRecognized
    }
    
    // Print hardware information if requested.
    var logLevel: UInt64?
    if let cString = getenv("GPUINFO_LOG_LEVEL") {
      let stringValue = String(cString: cString)
      guard let integerValue = UInt64(stringValue) else {
        let message = "Invalid log level: '\(stringValue)'"
        throw GPUInfoError(description: message)
      }
      logLevel = integerValue
    }
    if let logLevel, logLevel >= 1 {
      logHardwareSpecifications()
    }
  }
  
  /// Log hardware information to the console.
  private func logHardwareSpecifications() {
    // Print out some information about the device using its properties
//      print("GPU device name: \(device.mtlDevice.name)")
    
    // EDIT: Above is the only source of a compiler error that required
    // modification. `mtlDevice` is internal and can't be accessed this way.
    //
    // I changed the public API so that it provided a name.
    print("GPU name: \(self.name)")
    print("GPU vendor: \(self.vendor)")
    print("GPU core count: \(self.coreCount)")
    print("GPU clock frequency: \(self.clockFrequency / 1e9) GHz")
    print("GPU bandwidth: \(rint(self.bandwidth / 1e8) / 1e1) GB/s")
    print("GPU FLOPS: \(rint(self.flops / 1e9) / 1e3) TFLOPS")
    print("GPU IPS: \(rint(self.ips / 1e9) / 1e3) TIPS")
    
    let megabyte = 1024 * 1024
    let gigabyte = 1024 * 1024 * 1024
    let slc = self.systemLevelCache / megabyte
    print("GPU system level cache: \(slc) MB")
    
    if self.memory % gigabyte == 0 {
      print("GPU memory: \(self.memory / gigabyte) GB")
    } else {
      let memory_gigabytes = Double(self.memory) / Double(gigabyte)
      print("GPU memory: \(rint(memory_gigabytes * 1e2) / 1e2) GB")
    }
    
    // Print the Metal GPU family
    let delta = self.family.rawValue - MTLGPUFamily.apple1.rawValue
    print("GPU family: Apple \(delta + 1)")
  }
  
  /// Deinitialize the device object.
  deinit {
    #if arch(x86_64)
    
    #elseif os(macOS)
    IOObjectRelease(gpuEntry)
    #endif
    _cName.deallocate()
    _cVendor.deallocate()
  }
}
