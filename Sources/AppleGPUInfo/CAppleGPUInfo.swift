//
//  CAppleGPUInfo.swift
//  
//
//  Created by Philip Turner on 3/23/23.
//

import Foundation

// C API - exported symbols loadable from the dylib.

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

@_cdecl("GPUInfoDevice_vendor")
@usableFromInline
internal func GPUInfoDevice_vendor(
  _ pointerDevice: UnsafeMutableRawPointer
) -> UnsafePointer<CChar> {
  // Get an unmanaged reference from pointerDevice
  let unmanagedDevice = Unmanaged<GPUInfoDevice>.fromOpaque(pointerDevice)

  // Get a Swift class object from unmanagedDevice
  let device = unmanagedDevice.takeUnretainedValue()
  
  // Return C-accessible copy of string contents
  return UnsafePointer(device._cVendor)
}

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

/// The Metal GPU family (as an integer).
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
