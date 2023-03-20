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
  
  // Set up before each test method
  override func setUp() {
    super.setUp()
    // Arrange: create a device instance
    device = try? AppleGPUDevice()
  }
  
  // Tear down after each test method
  override func tearDown() {
    // Release the device instance
    device = nil
    super.tearDown()
  }
  
  // Test if the name is valid
  func testNameIsValid() {
    // Act: get the name property
    let name = device.name
    
    // Assert: check that the name contains "Apple M"
    XCTAssertEqual(name.prefix(7), "Apple M")
  }
  
  // Test if the device has a positive core count
  func testCoreCountIsPositive() {
    // Act: get the core count property
    let coreCount = device.coreCount
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(coreCount, 0, "Core count should be positive.")
  }
  
  // Test if the device has a valid clock frequency range
  func testClockFrequencyIsValid() {
    // Act: get the clock frequency property
    let clockFrequency = device.clockFrequency
    
    // Assert: check if it is between 0 and 10 GHz
    XCTAssertGreaterThanOrEqual(clockFrequency, 0, "Clock frequency should be non-negative.")
    XCTAssertLessThanOrEqual(clockFrequency, pow(10,10), "Clock frequency should be less than or equal to 10 GHz.")
  }
  
  // Test if the device has a positive bandwidth
  func testBandwidthIsPositive() {
    // Act: get the bandwidth property
    let bandwidth = device.bandwidth
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(bandwidth, 0, "Bandwidth should be positive.")
  }
  
  // Test if the device has a positive flops value
  func testFlopsIsPositive() {
    // Act: get the flops property
    let flops = device.flops
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(flops, 0, "Flops should be positive.")
  }
  
  // Test if the device has a positive system level cache size
  func testSystemLevelCacheIsPositive() {
    // Act: get the system level cache property
    let systemLevelCache = device.systemLevelCache
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(systemLevelCache, 0, "System level cache should be positive.")
  }
  
  // Test if the device has a positive memory size
  func testMemoryIsPositive() {
    // Act: get the memory property
    let memory = device.memory
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(memory, 0, "Memory should be positive.")
  }
  
  // Test if the family is valid
  func testFamilyIsValid() {
    // Act: get the family property
    let family = device.family
    
    // Assert: check if it is at least Apple 7
    let reference = MTLGPUFamily.apple7.rawValue
    XCTAssertGreaterThanOrEqual(family.rawValue, reference)
    
  }
}
