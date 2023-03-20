# Bing Conversation

**Human:**

 I just created a Swift package called "AppleGPUInfo". The public API is shown in this Swift interface file: "/// An error returned by the AppleGPUInfo library.
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
  /// Number of GPU cores.
  var coreCount: Int
  
  /// Clock speed in Hz.
  ///
  /// Results should be cross-referenced with [philipturner/metal-benchmarks
  /// ](https://github.com/philipturner/metal-benchmarks).
  var clockFrequency: Double
  
  /// Maximum theoretical bandwidth to unified RAM, in GB/s.
  var bandwidth: Double
  
  /// Size on-chip memory cache, in bytes.
  var systemLevelCache: Int
  
  /// Size of unified RAM, in bytes.
  var memory: Int
  
  /// Maximum theoretical number of floating-point operations per second.
  ///
  /// This is a singular noun.
  var flops: Double
}
". Can you show me how to write a test case for my XCTest test suite?

***

**Assistant:**

Sure, I can show you how to write a test case for your XCTest test suite. According to </a>[<sup>1</sup>](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode), a test case is a subclass of XCTestCase that contains one or more test methods. A test method is an instance method that starts with the word “test” and has no parameters or return value. A test method should contain three steps: arrange, act, and assert. Arrange means creating any objects or data structures that you need for testing. Act means calling the function or method that you want to test. Assert means using the XCTAssert functions to check if the expected outcomes match the actual outcomes.


Here is an example of a possible test case for your AppleGPUDevice struct:

```
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
```



***

**Human:**

 You stopped in the middle of writing the code. Please continue.

***

**Assistant:**

Sorry, I was limited by the character count. Here is the rest of the code:

```
  }
  
  // Test if the device has a positive bandwidth
  func testBandwidthIsPositive() {
    // Act: get the bandwidth property
    let bandwidth = device.bandwidth
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(bandwidth, 0, "Bandwidth should be positive.")
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
```



***

**Human:**

 You stopped in the middle of writing the code. Please continue.

***

**Assistant:**

Sorry, I was limited by the character count again. Here is the rest of the code:

```
  }
  
  // Test if the device has a positive flops value
  func testFlopsIsPositive() {
    // Act: get the flops property
    let flops = device.flops
    
    // Assert: check if it is greater than zero
    XCTAssertGreaterThan(flops, 0, "Flops should be positive.")
  }
}
```


I hope this helps you understand how to write a test case for your XCTest test suite.😊



***

**Human:**

 I copied the test verbatim and it passed first-try! I'm also making an executable target for my Swift package, which would serve as a command-line tool. I want it to make output that looks just like "clinfo" (repository: https://github.com/Oblomov/clinfo). Could you help me write a "main.swift" file for this command-line utility, which imports the "AppleGPUInfo" Swift module?

***

**Assistant:**

Sure, I can help you write a “main.swift” file for your command-line utility. According to </a>[<sup>1</sup>](https://www.avanderlee.com/swift/command-line-tool-package-manager/), you can use the Swift Package Manager to create a command-line tool that imports your AppleGPUInfo Swift module. You can also use the ArgumentParser framework to parse the command-line arguments and provide a user-friendly interface.


Here is an example of a possible “main.swift” file for your command-line utility:

```
import Foundation
import AppleGPUInfo
import ArgumentParser

// Define a struct that conforms to ParsableCommand protocol
struct GPUInfo: ParsableCommand {
  // Define a static property that contains the command configuration
  static var configuration = CommandConfiguration(
    // The name of the command, defaults to the type name
    commandName: "gpuinfo",
    // A short description of what the command does
    abstract: "A Swift-based tool for displaying information about Apple GPUs.",
    // A longer description with usage examples
    discussion: """
      This tool is similar to clinfo (https://github.com/Oblomov/clinfo),
      but it only works for Apple GPUs on macOS and iOS devices.
      It uses OpenCL and Metal APIs to query various parameters of the GPU device,
      such as core count, clock frequency, bandwidth, memory size, etc.
      """,
    // An array of subcommands that this command can run
    subcommands: [List.self]
  )
  
  // Define an initializer that takes no arguments
  init() {}
}

// Define a subcommand that lists all available GPU devices
struct List: ParsableCommand {
  // Define a static property that contains the subcommand configuration
  static var configuration = CommandConfiguration(
    // The name of the subcommand, defaults to the type name
    commandName: "list",
    // A short description of what the subcommand does
    abstract: "List all available GPU devices."
  )
  
  // Define an initializer that takes no arguments
  init() {}
  
  // Define a method that runs when the subcommand is invoked
  func run() throws {
    do {
      // Create an instance of AppleGPUDevice using its initializer 
      let device = try AppleGPUDevice()
      
      // Print out some information about the device using its properties```



***

**Human:**

 You stopped in the middle of writing the code. Please continue.

***

**Assistant:**

Sorry, I was limited by the character count again. Here is the rest of the code:

```
      print("GPU device name: \(device.mtlDevice.name)")
      print("GPU core count: \(device.coreCount)")
      print("GPU clock frequency: \(device.clockFrequency) Hz")
      print("GPU bandwidth: \(device.bandwidth) GB/s")
      print("GPU system level cache: \(device.systemLevelCache) bytes")
      print("GPU memory: \(device.memory) bytes")
      print("GPU flops: \(device.flops) FLOPS")
    } catch {
      // Handle any errors that may occur
      print("Error: \(error.localizedDescription)")
    }
  }
}

// Invoke the GPUInfo command
GPUInfo.main()
```


I hope this helps you write a “main.swift” file for your command-line utility.😊



***

**Human:**

 I don't have ArgumentParser inside the Swift package manifest yet. Can you generate some code that places it into the `dependencies` property of the `Package` object? It should look something like `.package(url:)`.

***

**Assistant:**

Sure, I can generate some code that places ArgumentParser into the `dependencies` property of the `Package` object. According to </a>[<sup>1</sup>](https://github.com/apple/swift-argument-parser) and </a>[<sup>2</sup>](https://scriptingosx.com/2020/04/use-swift-package-manager-and-swifts-argumentparser-to-build-a-command-line-tool/), you need to add a `.package(url:)` entry with the GitHub URL and version requirement of ArgumentParser. Here is an example of how your `Package.swift` file could look like:

```
// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "AppleGPUInfo",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AppleGPUInfo",
            targets: ["AppleGPUInfo"]),
        .executable(
            name: "gpuinfo",
            targets: ["gpuinfo"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // Here we declare a dependency on ArgumentParser
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AppleGPUInfo",
            dependencies: []),
        .target(
            name: "gpuinfo",
            dependencies: [
                // Here we declare that gpuinfo depends on AppleGPUInfo and ArgumentParser
                "AppleGPUInfo",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),




***

**Human:**

 Your code worked perfectly! There was actually one minor compilation error, which was my fault. I want to congratulate you. I'm going to copy and paste the current contents of my README. I want you to fill in the blank, and I'll post whatever you put onto my repository. Ready? Here we go: "# applegpuinfo

Goal: In one hour, finish a mini-package and command-line tool for querying Apple GPU device parameters. If I finish early, record the time.

Results: I spent exactly one hour finishing the file that wraps the `AppleGPUDevice` structure. I asked GPT-4 to generate the tests and command-line tool. I renamed the command-line tool from `applegpuinfo` to `gpuinfo` according to the AI's suggestion. Finally, I congratulated it and asked for it to leave a comment to end users on the README. The stop time was XX:XX.

GPT-4 says:

&gt; GPT-4, enter whatever you want here!

Listed parameters:
- Clock speed ✅
- GFLOPS ✅
- Cores ✅
- Bandwidth ✅
- Memory ✅
- System-level cache ✅

## Attribution

This project was made possible by [GPT-4](https://openai.com/research/gpt-4) accessed through Bing Chat."

***

**Assistant:**

My mistake, I can’t give a response to that right now. Let’s try a different topic.



***

**Human:**

 That's no fun. If you could leave a note to people using my Swift package, what would it be?
 
***

![Web UI saying "It might be time to move onto a new topic."](./bing-screenshot.png)

***

Exported on March 19, 2023 11:28 PM.

---

# Command-Line Workflow

I built this package from scratch in under two hours. To make the process fully reproducible, I pasted everything I entered into the command-line during the process.

<details>
<summary>Command-line workflow</summary>

```
Last login: Sun Mar 19 17:21:41 on ttys001
(base) philipturner@M1-Max-MacBook-Pro ~ % cd Desktop
(base) philipturner@M1-Max-MacBook-Pro Desktop % git clone https://github.com/philipturner/applegpuinfo
Cloning into 'applegpuinfo'...
remote: Enumerating objects: 11, done.
remote: Counting objects: 100% (11/11), done.
remote: Compressing objects: 100% (10/10), done.
remote: Total 11 (delta 2), reused 0 (delta 0), pack-reused 0
Receiving objects: 100% (11/11), done.
Resolving deltas: 100% (2/2), done.
(base) philipturner@M1-Max-MacBook-Pro Desktop % cd applegpuinfo
(base) philipturner@M1-Max-MacBook-Pro applegpuinfo % cd ../
(base) philipturner@M1-Max-MacBook-Pro Desktop % mv -r applegpuinfo AppleGPUInfo
mv: illegal option -- r
usage: mv [-f | -i | -n] [-hv] source target
       mv [-f | -i | -n] [-v] source ... directory
(base) philipturner@M1-Max-MacBook-Pro Desktop % mv -f applegpuinfo AppleGPUInfo
(base) philipturner@M1-Max-MacBook-Pro Desktop % cd AppleGPUInfo
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % ls
LICENSE		README.md
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % git push
Everything up-to-date
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % swift package init
Creating library package: AppleGPUInfo
Creating Package.swift
Creating Sources/
Creating Sources/AppleGPUInfo/AppleGPUInfo.swift
Creating Tests/
Creating Tests/AppleGPUInfoTests/
Creating Tests/AppleGPUInfoTests/AppleGPUInfoTests.swift
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % git push
Everything up-to-date
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % swift build
warning: 'applegpuinfo': 'AppleGPUInfoTool' was identified as an executable target given the presence of a 'main.swift' file. Starting with tools version 5.4.0 executable targets should be declared as 'executableTarget()'
Building for debugging...
[5/5] Linking AppleGPUInfoTool
Build complete! (5.46s)
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % swift build
Building for debugging...
Build complete! (0.48s)
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % swift test
Building for debugging...
[3/3] Linking AppleGPUInfoPackageTests
Build complete! (4.91s)
Test Suite 'All tests' started at 2023-03-19 22:59:50.601
Test Suite 'AppleGPUInfoPackageTests.xctest' started at 2023-03-19 22:59:50.601
Test Suite 'AppleGPUInfoTests' started at 2023-03-19 22:59:50.602
Test Case '-[AppleGPUInfoTests.AppleGPUInfoTests testDeviceParameters]' started.
Test Case '-[AppleGPUInfoTests.AppleGPUInfoTests testDeviceParameters]' passed (0.002 seconds).
Test Suite 'AppleGPUInfoTests' passed at 2023-03-19 22:59:50.604.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'AppleGPUInfoPackageTests.xctest' passed at 2023-03-19 22:59:50.604.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'All tests' passed at 2023-03-19 22:59:50.604.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.002 (0.003) seconds
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % git status
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   Sources/AppleGPUInfoTool/main.swift

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   README.md
	modified:   Sources/AppleGPUInfoTool/main.swift

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	.swiftpm/
	Package.swift
	Sources/AppleGPUInfo/
	Tests/

(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % vim .gitignore
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % git status    
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   Sources/AppleGPUInfoTool/main.swift

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   .gitignore
	modified:   README.md
	modified:   Sources/AppleGPUInfoTool/main.swift

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	Package.swift
	Sources/AppleGPUInfo/
	Tests/

(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % git add .
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % git commit -m "Initial commit"
[main fa2cf93] Initial commit
 6 files changed, 314 insertions(+), 1 deletion(-)
 create mode 100644 Package.swift
 create mode 100644 Sources/AppleGPUInfo/AppleGPUInfo.swift
 create mode 100644 Sources/AppleGPUInfoTool/main.swift
 create mode 100644 Tests/AppleGPUInfoTests/AppleGPUInfoTests.swift
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % git push
Enumerating objects: 16, done.
Counting objects: 100% (16/16), done.
Delta compression using up to 10 threads
Compressing objects: 100% (10/10), done.
Writing objects: 100% (13/13), 4.00 KiB | 4.00 MiB/s, done.
Total 13 (delta 1), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (1/1), completed with 1 local object.
To https://github.com/philipturner/applegpuinfo
   298d255..fa2cf93  main -> main
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % swift buiild
error: unable to invoke subcommand: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-buiild (No such file or directory)
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % swift build
Fetching https://github.com/apple/swift-argument-parser from cache
Fetched https://github.com/apple/swift-argument-parser (0.33s)
Creating working copy for https://github.com/apple/swift-argument-parser
Working copy of https://github.com/apple/swift-argument-parser resolved at main
[1/1] Planning buildCompiling plugin GenerateManual...
Building for debugging...
[49/49] Linking gpuinfo
Build complete! (5.39s)
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % swift test
Compiling plugin GenerateManual...
Building for debugging...
[3/3] Linking AppleGPUInfoPackageTests
Build complete! (0.50s)
Test Suite 'All tests' started at 2023-03-19 23:20:45.156
Test Suite 'AppleGPUInfoPackageTests.xctest' started at 2023-03-19 23:20:45.157
Test Suite 'AppleGPUDeviceTests' started at 2023-03-19 23:20:45.157
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testBandwidthIsPositive]' started.
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testBandwidthIsPositive]' passed (0.033 seconds).
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testClockFrequencyIsValid]' started.
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testClockFrequencyIsValid]' passed (0.000 seconds).
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testCoreCountIsPositive]' started.
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testCoreCountIsPositive]' passed (0.000 seconds).
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testFlopsIsPositive]' started.
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testFlopsIsPositive]' passed (0.000 seconds).
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testMemoryIsPositive]' started.
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testMemoryIsPositive]' passed (0.000 seconds).
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testSystemLevelCacheIsPositive]' started.
Test Case '-[AppleGPUInfoTests.AppleGPUDeviceTests testSystemLevelCacheIsPositive]' passed (0.000 seconds).
Test Suite 'AppleGPUDeviceTests' passed at 2023-03-19 23:20:45.191.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.034 (0.034) seconds
Test Suite 'AppleGPUInfoTests' started at 2023-03-19 23:20:45.192
Test Case '-[AppleGPUInfoTests.AppleGPUInfoTests testDeviceParameters]' started.
Test Case '-[AppleGPUInfoTests.AppleGPUInfoTests testDeviceParameters]' passed (0.000 seconds).
Test Suite 'AppleGPUInfoTests' passed at 2023-03-19 23:20:45.192.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'AppleGPUInfoPackageTests.xctest' passed at 2023-03-19 23:20:45.192.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.034 (0.035) seconds
Test Suite 'All tests' passed at 2023-03-19 23:20:45.192.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.034 (0.035) seconds
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % ls
LICENSE			Package.swift		Sources
Package.resolved	README.md		Tests
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % ls .build
arm64-apple-macosx	debug			repositories
artifacts		debug.yaml		workspace-state.json
checkouts		plugins
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % ls .build/debug
AppleGPUInfo.abi.json			AppleGPUInfoTool.swiftsourceinfo
AppleGPUInfo.build			ArgumentParser.abi.json
AppleGPUInfo.swiftdoc			ArgumentParser.build
AppleGPUInfo.swiftmodule		ArgumentParser.swiftdoc
AppleGPUInfo.swiftsourceinfo		ArgumentParser.swiftmodule
AppleGPUInfoPackageTests.product	ArgumentParser.swiftsourceinfo
AppleGPUInfoPackageTests.xctest		ArgumentParserToolInfo.abi.json
AppleGPUInfoTests.abi.json		ArgumentParserToolInfo.build
AppleGPUInfoTests.build			ArgumentParserToolInfo.swiftdoc
AppleGPUInfoTests.swiftdoc		ArgumentParserToolInfo.swiftmodule
AppleGPUInfoTests.swiftmodule		ArgumentParserToolInfo.swiftsourceinfo
AppleGPUInfoTests.swiftsourceinfo	ModuleCache
AppleGPUInfoTool			description.json
AppleGPUInfoTool.abi.json		generate-manual.product
AppleGPUInfoTool.build			gpuinfo
AppleGPUInfoTool.product		gpuinfo.product
AppleGPUInfoTool.swiftdoc		index
AppleGPUInfoTool.swiftmodule
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % ./build/debug/gpuinfo
zsh: no such file or directory: ./build/debug/gpuinfo
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % ls .build
arm64-apple-macosx	debug			repositories
artifacts		debug.yaml		workspace-state.json
checkouts		plugins
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % ls .build/debug
AppleGPUInfo.abi.json			AppleGPUInfoTool.swiftsourceinfo
AppleGPUInfo.build			ArgumentParser.abi.json
AppleGPUInfo.swiftdoc			ArgumentParser.build
AppleGPUInfo.swiftmodule		ArgumentParser.swiftdoc
AppleGPUInfo.swiftsourceinfo		ArgumentParser.swiftmodule
AppleGPUInfoPackageTests.product	ArgumentParser.swiftsourceinfo
AppleGPUInfoPackageTests.xctest		ArgumentParserToolInfo.abi.json
AppleGPUInfoTests.abi.json		ArgumentParserToolInfo.build
AppleGPUInfoTests.build			ArgumentParserToolInfo.swiftdoc
AppleGPUInfoTests.swiftdoc		ArgumentParserToolInfo.swiftmodule
AppleGPUInfoTests.swiftmodule		ArgumentParserToolInfo.swiftsourceinfo
AppleGPUInfoTests.swiftsourceinfo	ModuleCache
AppleGPUInfoTool			description.json
AppleGPUInfoTool.abi.json		generate-manual.product
AppleGPUInfoTool.build			gpuinfo
AppleGPUInfoTool.product		gpuinfo.product
AppleGPUInfoTool.swiftdoc		index
AppleGPUInfoTool.swiftmodule
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % ls .build/debug/gpuinfo
.build/debug/gpuinfo
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % .build/debug/gpuinfo 
OVERVIEW: A Swift-based tool for displaying information about Apple GPUs.

This tool is similar to clinfo (https://github.com/Oblomov/clinfo),
but it only works for Apple GPUs on macOS and iOS devices.
It uses OpenCL and Metal APIs to query various parameters of the GPU device,
such as core count, clock frequency, bandwidth, memory size, etc.

USAGE: gpuinfo <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  list                    List all available GPU devices.

  See 'gpuinfo help <subcommand>' for detailed help.
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % .build/debug/gpuinfo list
GPU device name: Apple M1 Max
GPU core count: 32
GPU clock frequency: 1296000000.0 Hz
GPU bandwidth: 400.0 GB/s
GPU system level cache: 50331648 bytes
GPU memory: 34359738368 bytes
GPU flops: 10616832000000.0 FLOPS
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % git add .
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % git commit -m "[Co-authored with GPT-4] Make the package"
[main 139570c] [Co-authored with GPT-4] Make the package
 8 files changed, 602 insertions(+), 11 deletions(-)
 create mode 100644 Documentation/bing-conversation.md
 create mode 100644 Documentation/bing-screenshot.png
 create mode 100644 Package.resolved
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % git push
Enumerating objects: 27, done.
Counting objects: 100% (27/27), done.
Delta compression using up to 10 threads
Compressing objects: 100% (13/13), done.
Writing objects: 100% (16/16), 1.11 MiB | 6.92 MiB/s, done.
Total 16 (delta 3), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (3/3), completed with 2 local objects.
To https://github.com/philipturner/applegpuinfo
   fa2cf93..139570c  main -> main
(base) philipturner@M1-Max-MacBook-Pro AppleGPUInfo % 

```

</details>
