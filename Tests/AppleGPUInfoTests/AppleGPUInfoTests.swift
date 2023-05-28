import XCTest
@testable import AppleGPUInfo

class GPUInfoDeviceTests: XCTestCase {
  // A test device instance
  var device: GPUInfoDevice!
  var cDevice: UnsafeMutableRawPointer!
  
  // Set up before each test method
  override func setUp() {
    super.setUp()
    // Arrange: create a device instance
    device = try? GPUInfoDevice()
    
    var error: UnsafeMutableRawPointer?
    cDevice = GPUInfoDevice_init(&error)
    XCTAssertNil(error, String(cString: GPUInfoError_description(error!)))
  }
  
  // Tear down after each test method
  override func tearDown() {
    // Release the device instance
    device = nil
    GPUInfoDevice_deinit(cDevice)
    super.tearDown()
  }
  
  // Test if the registry ID is valid.
  func testRegistryIDIsValid() {
    // TODO: Ensure the device can be initialized both with and without the
    // registry ID environment variable. Someone may have set that variable for
    // this test, so remove the current value and restore it afterward.
    let key = "GPUINFO_REGISTRY_ID"
    var currentRegistryID: String?
    if let cString = getenv(key) {
      currentRegistryID = String(cString: cString)
      unsetenv(key)
    }
    
    XCTAssertNoThrow(try GPUInfoDevice())
    setenv(key, "abcd", 1)
    XCTAssertThrowsError(try GPUInfoDevice())
    
    // Ensure it throws and error through the C API.
    var error: UnsafeMutableRawPointer?
    if let cDevice = GPUInfoDevice_init(&error) {
      GPUInfoDevice_deinit(cDevice)
    }
    XCTAssertNotNil(error)
    if let error {
      let description = String(cString: GPUInfoError_description(error))
      let expected = "Invalid registry ID:"
      XCTAssertEqual(String(description.prefix(expected.count)), expected)
      GPUInfoError_deinit(error)
    }
    error = nil
    
#if os(macOS)
    let mtlDevice = MTLCopyAllDevices().last!
#else
    let mtlDevice = MTLCreateSystemDefaultDevice()!
#endif
    
    // Ensure a nonexistent registry ID is considered invalid.
    setenv(key, String(mtlDevice.registryID ^ 1), 1)
    if let cDevice = GPUInfoDevice_init(&error) {
      GPUInfoDevice_deinit(cDevice)
    }
    XCTAssertNotNil(error)
    if let error {
      let description = String(cString: GPUInfoError_description(error))
      let expected = "Could not find device matching registry ID:"
      XCTAssertEqual(String(description.prefix(expected.count)), expected)
      GPUInfoError_deinit(error)
    }
    error = nil
    
    // Ensure an existing registry ID is considered valid.
    setenv(key, String(mtlDevice.registryID), 1)
    XCTAssertNoThrow(try GPUInfoDevice())
    
    if let currentRegistryID {
      setenv(key, currentRegistryID, 1)
    }
  }
  
  // Test if the name is valid
  func testNameIsValid() {
    // Act: get the name property
    let name = device.name
    let cName = GPUInfoDevice_name(cDevice)
    
    // Assert: check that the name contains "Apple "
    XCTAssertEqual(name.prefix(6), "Apple ")
    XCTAssertEqual(String(cString: cName).prefix(6), "Apple ")
  }
  
  // Test if the vendor is valid
  func testVendorIsValid() {
    // Act: get the vendor property
    let vendor = device.vendor
    let cVendor = GPUInfoDevice_vendor(cDevice)
    
    // Assert: check that the vendor is "Apple"
    let validVendors = ["Apple", "AMD", "Intel"]
    XCTAssert(validVendors.contains(vendor))
    XCTAssert(validVendors.contains(String(cString: cVendor)))
  }
  
  // Test if the device has a positive core count
  func testCoreCountIsPositive() {
    // Act: get the core count property
    let coreCount = device.coreCount
    let cCoreCount = GPUInfoDevice_coreCount(cDevice)
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(coreCount, 0, "Core count should be positive.")
    XCTAssertGreaterThan(cCoreCount, 0, "Core count should be positive.")
  }
  
  // Test if the device has a valid clock frequency range
  func testClockFrequencyIsValid() {
    // Act: get the clock frequency property
    let clockFrequency = device.clockFrequency
    let cClockFrequency = GPUInfoDevice_clockFrequency(cDevice)
    
    // Assert: check if it is between 0 and 10 GHz
    XCTAssertGreaterThanOrEqual(clockFrequency, 0, """
      Clock frequency should be non-negative.
      """)
    XCTAssertGreaterThanOrEqual(cClockFrequency, 0, """
      Clock frequency should be non-negative.
      """)
    XCTAssertLessThanOrEqual(clockFrequency, 10e10, """
      Clock frequency should be less than or equal to 10 GHz.
      """)
    XCTAssertLessThanOrEqual(cClockFrequency, 10e10, """
      Clock frequency should be less than or equal to 10 GHz.
      """)
  }
  
  // Test if the device has a positive bandwidth
  func testBandwidthIsPositive() {
    // Act: get the bandwidth property
    let bandwidth = device.bandwidth
    let cBandwidth = GPUInfoDevice_bandwidth(cDevice)
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(bandwidth, 0, "Bandwidth should be positive.")
    XCTAssertGreaterThan(cBandwidth, 0, "Bandwidth should be positive.")
  }
  
  // Test if the device has a positive flops value
  func testFLOPSIsPositive() {
    // Act: get the flops property
    let flops = device.flops
    let cFlops = GPUInfoDevice_flops(cDevice)
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(flops, 0, "Flops should be positive.")
    XCTAssertGreaterThan(cFlops, 0, "Flops should be positive.")
  }
  
  // Test if the device has a positive instructins per second value
  func testIPSIsPositive() {
    // Act: get the instructions per second property
    let ips = device.ips
    let cIPS = GPUInfoDevice_ips(cDevice)
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(ips, 0, "IPS should be positive.")
    XCTAssertGreaterThan(cIPS, 0, "IPS should be positive.")
  }
  
  // Test if the device has a positive system level cache size
  func testSystemLevelCacheIsNonNegative() {
    // Act: get the system level cache property
    let systemLevelCache = device.systemLevelCache
    let cSystemLevelCache = GPUInfoDevice_systemLevelCache(cDevice)
    
    // Assert: check if it is greater than or equal to zero
    XCTAssertGreaterThanOrEqual(systemLevelCache, 0, """
      System level cache should be positive.
      """)
    XCTAssertGreaterThanOrEqual(cSystemLevelCache, 0, """
      System level cache should be positive.
      """)
  }
  
  // Test if the device has a positive memory size
  func testMemoryIsPositive() {
    // Act: get the memory property
    let memory = device.memory
    let cMemory = GPUInfoDevice_memory(cDevice)
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(memory, 0, "Memory should be positive.")
    XCTAssertGreaterThan(cMemory, 0, "Memory should be positive.")
  }
  
  // Test if the family is valid
  func testFamilyIsValid() {
    // Act: get the family property
    let family = device.family
    let cFamily = GPUInfoDevice_family(cDevice)
    
    // Assert: check if it is at least Apple 1
    let reference = MTLGPUFamily.apple1.rawValue
    XCTAssertGreaterThanOrEqual(family.rawValue, reference)
    XCTAssertGreaterThanOrEqual(Int(cFamily), reference)
    
  }
  
  // Test if the C interface to the error works correctly.
  func testErrorIsValid() {
    let message = "This error should be valid."
    let error = GPUInfoError_init(message)
    let description = GPUInfoError_description(error)
    XCTAssertEqual(String(cString: description), message)
    GPUInfoError_deinit(error)
  }
}
