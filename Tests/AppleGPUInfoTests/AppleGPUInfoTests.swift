import XCTest
@testable import AppleGPUInfo

final class AppleGPUInfoTests: XCTestCase {
  // Generated using GPT-4. Methodology:
  // - Feed the interface blurb from "AppleGPUInfo.swift" into the chat.
  // - Ask for a test case, copy and refine what it tests.
  // - If it missed anything, ask for that as well.
  func testDeviceParameters() throws {
      
  }
}

// Auto-generated.

import XCTest
@testable import AppleGPUInfo

class AppleGPUDeviceTests: XCTestCase {
  // A test device instance
  var device: AppleGPUDevice!
  var cDevice: UnsafeMutableRawPointer!
  
  // Set up before each test method
  override func setUp() {
    super.setUp()
    // Arrange: create a device instance
    device = try? AppleGPUDevice()
    
    var error: UnsafeMutableRawPointer?
    cDevice = AppleGPUDevice_init(&error)
    XCTAssertNil(error, String(cString: AppleGPUError_description(error!)))
  }
  
  // Tear down after each test method
  override func tearDown() {
    // Release the device instance
    device = nil
    AppleGPUDevice_deinit(cDevice)
    super.tearDown()
  }
  
  // Test if the name is valid
  func testNameIsValid() {
    // Act: get the name property
    let name = device.name
    let cName = AppleGPUDevice_name(cDevice)
    
    // Assert: check that the name contains "Apple "
    XCTAssertEqual(name.prefix(6), "Apple ")
    XCTAssertEqual(String(cString: cName).prefix(6), "Apple ")
  }
  
  // Test if the device has a positive core count
  func testCoreCountIsPositive() {
    // Act: get the core count property
    let coreCount = device.coreCount
    let cCoreCount = AppleGPUDevice_coreCount(cDevice)
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(coreCount, 0, "Core count should be positive.")
    XCTAssertGreaterThan(cCoreCount, 0, "Core count should be positive.")
  }
  
  // Test if the device has a valid clock frequency range
  func testClockFrequencyIsValid() {
    // Act: get the clock frequency property
    let clockFrequency = device.clockFrequency
    let cClockFrequency = AppleGPUDevice_clockFrequency(cDevice)
    
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
    let cBandwidth = AppleGPUDevice_bandwidth(cDevice)
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(bandwidth, 0, "Bandwidth should be positive.")
    XCTAssertGreaterThan(cBandwidth, 0, "Bandwidth should be positive.")
  }
  
  // Test if the device has a positive flops value
  func testFlopsIsPositive() {
    // Act: get the flops property
    let flops = device.flops
    let cFlops = AppleGPUDevice_flops(cDevice)
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(flops, 0, "Flops should be positive.")
    XCTAssertGreaterThan(cFlops, 0, "Flops should be positive.")
  }
  
  // Test if the device has a positive system level cache size
  func testSystemLevelCacheIsNonNegative() {
    // Act: get the system level cache property
    let systemLevelCache = device.systemLevelCache
    let cSystemLevelCache = AppleGPUDevice_systemLevelCache(cDevice)
    
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
    let cMemory = AppleGPUDevice_memory(cDevice)
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(memory, 0, "Memory should be positive.")
    XCTAssertGreaterThan(cMemory, 0, "Memory should be positive.")
  }
  
  // Test if the family is valid
  func testFamilyIsValid() {
    // Act: get the family property
    let family = device.family
    let cFamily = AppleGPUDevice_family(cDevice)
    
    // Assert: check if it is at least Apple 2
    let reference = MTLGPUFamily.apple2.rawValue
    XCTAssertGreaterThanOrEqual(family.rawValue, reference)
    XCTAssertGreaterThanOrEqual(Int(cFamily), reference)
    
  }
  
  // Test if the C interface to the error works correctly.
  func testErrorIsValid() {
    let message = "This error should be valid."
    let error = AppleGPUError_init(message)
    let description = AppleGPUError_description(error)
    XCTAssertEqual(String(cString: description), message)
    AppleGPUError_deinit(error)
  }
}
