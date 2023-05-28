//
//  AppleGPUInfo.h
//
//
//  Created by Philip Turner on 5/28/23.
//

#ifndef AppleGPUInfo_h
#define AppleGPUInfo_h

#include <stdint.h>

extern "C" {

/// Initialize the error object.
void* GPUInfoError_init(const char* description);

/// Deinitialize the error object.
void GPUInfoError_deinit(void* pointerError);

/// The description of the error.
const char* GPUInfoError_description(void* pointerError);

/// Initialize the device object, returning any errors at +1 refcount.
///
/// Creating a `GPUInfoDevice` is a costly operation. If possible, create one
/// object and use it multiple times.
void* GPUInfoDevice_init(void** pointerError);

/// Deinitialize the device object.
void GPUInfoDevice_deinit(void* pointerDevice);

/// The full name of the GPU device.
const char* GPUInfoDevice_name(void* pointerDevice);

/// The manufacturer of the GPU device.
const char* GPUInfoDevice_vendor(void* pointerDevice);

/// The number of GPU cores.
int64_t GPUInfoDevice_coreCount(void* pointerDevice);

/// The clock speed in Hz.
///
/// Results should be cross-referenced with
/// [philipturner/metal-benchmarks](https://github.com/philipturner/metal-benchmarks).
double GPUInfoDevice_clockFrequency(void* pointerDevice);

/// The maximum theoretical bandwidth to random-access memory, in
/// bytes/second.
double GPUInfoDevice_bandwidth(void* pointerDevice);

/// The maximum theoretical number of floating-point operations per second.
///
/// The number of `Float32` operations performed each second through fused
/// multiply-add.
double GPUInfoDevice_flops(void* pointerDevice);

/// The maximum theoretical number of shader instructions per second.
///
/// The number of `Int32` add operations performed each second. See the
/// [Apple GPU ISA](https://github.com/dougallj/applegpu) for situations
/// where multiple operations are fused into one shader instruction.
double GPUInfoDevice_ips(void* pointerDevice);

/// The size of the on-chip memory cache, in bytes.
///
/// This property sometimes returns zero. If your application targets iPads
/// with the A9X or A10X chip, provide fallbacks for optimizations that
/// require a nonzero cache size.
int64_t GPUInfoDevice_systemLevelCache(void* pointerDevice);

/// The size of the device's random-access memory, in bytes.
int64_t GPUInfoDevice_memory(void* pointerDevice);

/// The Metal GPU family (as an integer).
int64_t GPUInfoDevice_family(void* pointerDevice);

}

#endif /* AppleGPUInfo_h */
