import OpenCL // TODO: Use IORegistry instead for iOS port
import Metal

// Public API for the Swift file (feed this into GPT-4):
#if false

/// An error returned by the AppleGPUInfo library.
public struct AppleGPUError: Error {
  var description: String
}

/// A data structure for querying parameters of an Apple-designed GPU.
public struct AppleGPUDevice {
  internal var clDevice: cl_device_id
  internal var mtlDevice: MTLDevice
  
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

fileprivate func handleCLError(
  _ code: Int32,
  line: UInt = #line,
  file: StaticString = #file
) throws {
  guard code == CL_SUCCESS else {
    var message = "Encountered OpenCL error code \(code)"
    message += " at \(file):\(line)"
    throw AppleGPUError(description: message)
  }
}

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

/// An error returned by the AppleGPUInfo library.
public struct AppleGPUError: Error {
  var description: String
}

/// A data structure for querying parameters of an Apple-designed GPU.
public struct AppleGPUDevice {
  internal var clDevice: cl_device_id
  internal var mtlDevice: MTLDevice
  
  public init() throws {
    let devices = MTLCopyAllDevices()
    guard let appleDevice = devices.first(where: {
      $0.supportsFamily(.apple7 )
    }) else {
      throw AppleGPUError(description: "This device does is not an Apple GPU.")
    }
    self.mtlDevice = appleDevice
    
    
    
    var platformIDs: [cl_platform_id?] = [nil]
    try handleCLError(clGetPlatformIDs(1, &platformIDs, nil))
    
    let platform = platformIDs[0]!
    let deviceType = cl_device_type(CL_DEVICE_TYPE_GPU)
    var clDevices: [cl_device_id?] = [nil]
    try handleCLError(clGetDeviceIDs(platform, deviceType, 1, &clDevices, nil))
    
    self.clDevice = clDevices[0]!
  }
}

// TODO: Cache these values to decrease overhead - fetch upon initialization.
public extension AppleGPUDevice {
  /// The full name of the GPU device.
  var name: String {
    return mtlDevice.name
  }
  
  /// Number of GPU cores.
  var coreCount: Int {
    // CL_DEVICE_MAX_COMPUTE_UNITS: cl_uint
    // The number of parallel compute units on the OpenCL device. A work-group
    // executes on a single compute unit. The minimum value is 1.
    let paramName = cl_device_info(CL_DEVICE_MAX_COMPUTE_UNITS)
    var maxComputeUnits: UInt32 = 0
    do {
      try handleCLError(
        clGetDeviceInfo(clDevice, paramName, 4, &maxComputeUnits, nil))
    } catch {
      fatalError(error.localizedDescription)
    }
    
    guard maxComputeUnits > 0 else {
      fatalError("Number of cores was zero.")
    }
    
    return Int(maxComputeUnits)
  }
  
  private enum Tier {
    case base
    case pro
    case max
    case ultra
    case unknown
  }
  
  private var tier: Tier {
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
    return tier
  }
  
  private var generation: Int {
    var name = mtlDevice.name
    name.removeFirst("Apple M".count)
    
    var generationString = ""
    for character in name {
      if character.isWholeNumber {
        generationString.append(character)
      } else {
        break
      }
    }
    guard let generation = Int(generationString) else {
      fatalError("""
        Could not transform string '\(generationString)' extracted from \
        '\(name)' into a number.
        """)
    }
    return generation
  }
  
  /// Clock speed in Hz.
  ///
  /// Results should be cross-referenced with [philipturner/metal-benchmarks
  /// ](https://github.com/philipturner/metal-benchmarks).
  var clockFrequency: Double {
    // First, find the tier of the Metal GPU.
    let tier = self.tier
    
    // Second, find the generation.
    let generation = self.generation
    
    switch generation {
    case 1:
      switch tier {
      case .base: return 1.278e9
      case .pro, .max, .ultra: return 1.296e9
      case .unknown: return 1.296e9
      }
    case 2:
      fallthrough
    default:
      switch tier {
      case .base: return 1.398e9
      case .pro, .max: return 1.398e9
      default: return 1.398e9
      }
    }
  }
  
  /// Maximum theoretical bandwidth to unified RAM, in bytes/second.
  var bandwidth: Double {
    switch generation {
    case 1:
      switch tier {
      case .base: return 68.2e9
      case .pro: return 200e9
      case .max: return 400e9
      case .ultra: return 800e9
      case .unknown: return 800e9
      }
    case 2:
      fallthrough
    default:
      switch tier {
      case .base: return 100e9
      case .pro: return 200e9
      case .max: return 400e9
      case .ultra: return 800e9
      case .unknown: return 800e9
      }
    }
  }
  
  /// Maximum theoretical number of floating-point operations per second.
  ///
  /// This is a singular noun.
  var flops: Double {
    let operationsPerClock = self.coreCount * 128 * 2
    return Double(operationsPerClock) * clockFrequency
  }
  
  /// Size of on-chip memory cache, in bytes.
  var systemLevelCache: Int {
    let megabyte = 1024 * 1024
    
    switch generation {
    case 1:
      switch tier {
      case .base: return 8 * megabyte
      case .pro: return 24 * megabyte
      case .max: return 48 * megabyte
      case .ultra: return 96 * megabyte
      case .unknown: return 96 * megabyte
      }
    case 2:
      fallthrough
    default:
      switch tier {
      case .base: return 8 * megabyte
      case .pro: return 24 * megabyte
      case .max: return 48 * megabyte
      case .ultra: return 96 * megabyte
      case .unknown: return 96 * megabyte
      }
    }
  }
  
  /// Size of unified RAM, in bytes.
  var memory: Int {
    var memorySize: Int = 0
    var sizeOfInt: Int = 8
    do {
      try handleSysctlError(
        sysctlbyname("hw.memsize", &memorySize, &sizeOfInt, nil, 0))
    } catch {
      fatalError(error.localizedDescription)
    }
    return memorySize
  }
  
  /// Metal GPU family.
  var family: MTLGPUFamily {
    // TODO: Recognize more than just Apple 7/8 when porting to iOS.
    var maxRecognized: MTLGPUFamily = .apple8
    while maxRecognized.rawValue >= 0 {
      if mtlDevice.supportsFamily(maxRecognized) {
        break
      } else {
        maxRecognized = .init(rawValue: maxRecognized.rawValue - 1)!
      }
    }
    return maxRecognized
  }
}
