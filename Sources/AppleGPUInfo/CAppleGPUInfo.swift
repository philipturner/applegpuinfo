//
//  CAppleGPUInfo.swift
//  
//
//  Created by Philip Turner on 3/23/23.
//

import Foundation

// C API - exported symbols loadable from the dylib.

/// Initialize the error object.
@_cdecl("GPUInfoError_init")
@usableFromInline
internal func GPUInfoError_init(
  _ description: UnsafePointer<CChar>
) -> UnsafeMutableRawPointer {
  // Create a Swift class object
  let error = GPUInfoError(
    description: String(cString: description, encoding: .utf8)!)

  // Convert it to an unsafe reference with +1 retain count
  let unmanagedError = Unmanaged.passRetained(error)

  // Get an UnsafeMutablePointer from unmanagedError
  return unmanagedError.toOpaque()
}

/// Deinitialize the error object.
@_cdecl("GPUInfoError_deinit")
@usableFromInline
internal func GPUInfoError_deinit(
  _ pointerError: UnsafeMutableRawPointer
) {
  // Get an unmanaged reference from pointerError
  let unmanagedError = Unmanaged<GPUInfoError>.fromOpaque(pointerError)
  
  // Release the object referenced by pointerError
  unmanagedError.release()
}

/// The description of the error.
@_cdecl("GPUInfoError_description")
@usableFromInline
internal func GPUInfoError_description(
  _ pointerError: UnsafeMutableRawPointer
) -> UnsafePointer<CChar> {
  // Get an unmanaged reference from pointerError
  let unmanagedError = Unmanaged<GPUInfoError>.fromOpaque(pointerError)
  
  // Get a Swift class reference to unmanagedError
  let error = unmanagedError.takeUnretainedValue()
  
  // Return C-accessible copy of string contents
  return UnsafePointer(error._cDescripton)
}

/// Initialize the device object, returning any errors at +1 refcount.
///
/// Creating an `GPUInfoDevice` is an expensive operation. If possible, only
/// call this initializer once.
@_cdecl("GPUInfoDevice_init")
@usableFromInline
internal func GPUInfoDevice_init(
  _ pointerError: UnsafeMutablePointer<UnsafeMutableRawPointer?>
) -> UnsafeMutableRawPointer? {
  var device: GPUInfoDevice
  
  do {
    // Create a Swift class object
    device = try GPUInfoDevice()
  } catch let error as GPUInfoError {
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
@_cdecl("GPUInfoDevice_deinit")
@usableFromInline
internal func GPUInfoDevice_deinit(
  _ pointerDevice: UnsafeMutableRawPointer
) {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoError>.fromOpaque(pointerDevice)
  
  // Release the object referenced by pointerDevice
  unmanagedDevice.release()
}

/// The full name of the GPU device.
@_cdecl("GPUInfoDevice_name")
@usableFromInline
internal func GPUInfoDevice_name(
  _ pointerDevice: UnsafeMutableRawPointer
) -> UnsafePointer<CChar> {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return C-accessible copy of string contents
  return UnsafePointer(device._cName)
}

/// Number of GPU cores.
@_cdecl("GPUInfoDevice_coreCount")
@usableFromInline
internal func GPUInfoDevice_coreCount(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Int64 {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the core count.
  return Int64(device.coreCount)
}

/// Clock speed in Hz.
///
/// Results should be cross-referenced with [philipturner/metal-benchmarks
/// ](https://github.com/philipturner/metal-benchmarks).
@_cdecl("GPUInfoDevice_clockFrequency")
@usableFromInline
internal func GPUInfoDevice_clockFrequency(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Double {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the clock frequency.
  return Double(device.clockFrequency)
}

/// Maximum theoretical bandwidth to unified RAM, in bytes/second.
@_cdecl("GPUInfoDevice_bandwidth")
@usableFromInline
internal func GPUInfoDevice_bandwidth(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Double {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the bandwidth.
  return Double(device.bandwidth)
}

/// Maximum theoretical number of floating-point operations per second.
///
/// The number of FP32 operations performed through fused multiply-add each
/// second. This is a singular noun.
@_cdecl("GPUInfoDevice_flops")
@usableFromInline
internal func GPUInfoDevice_flops(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Double {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the FLOPS.
  return Double(device.flops)
}

/// Maximum theoretical number of shader instructions per second.
///
/// The number of integer add operations performed each second. See the
/// [Apple GPU ISA](https://github.com/dougallj/applegpu) for instances
/// where multiple operations can be fused into one shader instruction.
@_cdecl("GPUInfoDevice_ips")
@usableFromInline
internal func GPUInfoDevice_ips(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Double {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the bandwidth.
  return Double(device.ips)
}

/// Size of on-chip memory cache, in bytes.
///
/// Do not assume a system-level cache exists; this property sometimes returns
/// zero. Provide fallbacks for optimizations that depend on SLC size.
@_cdecl("GPUInfoDevice_systemLevelCache")
@usableFromInline
internal func GPUInfoDevice_systemLevelCache(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Int64 {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the system level cache.
  return Int64(device.systemLevelCache)
}

/// Size of unified RAM, in bytes.
@_cdecl("GPUInfoDevice_memory")
@usableFromInline
internal func GPUInfoDevice_memory(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Int64 {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the system level cache.
  return Int64(device.memory)
}

/// Metal GPU family (as an integer).
@_cdecl("GPUInfoDevice_family")
@usableFromInline
internal func GPUInfoDevice_family(
  _ pointerDevice: UnsafeMutableRawPointer
) -> Int64 {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return the system level cache.
  return Int64(device.family.rawValue)
}
