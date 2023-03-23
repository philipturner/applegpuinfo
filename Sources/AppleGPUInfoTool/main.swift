//
//  main.swift
//  
//
//  Created by Philip Turner on 3/19/23.
//

import Foundation
import AppleGPUInfo
import ArgumentParser
import Metal

// Define a struct that conforms to ParsableCommand protocol
struct GPUInfoTool: ParsableCommand {
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
      It uses Metal and IOKit APIs to query various parameters of the GPU device,
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
      // Create an instance of GPUInfoDevice using its initializer
      let device = try GPUInfoDevice()
      
      // Print out some information about the device using its properties
//      print("GPU device name: \(device.mtlDevice.name)")
      
      // EDIT: Above is the only source of a compiler error that required
      // modification. `mtlDevice` is internal and can't be accessed this way.
      //
      // I changed the public API so that it provided a name.
      print("GPU name: \(device.name)")
      print("GPU core count: \(device.coreCount)")
      print("GPU clock frequency: \(device.clockFrequency / 1e9) GHz")
      print("GPU bandwidth: \(device.bandwidth / 1e9) GB/s")
      print("GPU FLOPS: \(rint(device.flops / 1e9) / 1e3) TFLOPS")
      print("GPU IPS: \(rint(device.ips / 1e9) / 1e3) TIPS")
      
      let megabyte = 1024 * 1024
      let gigabyte = 1024 * 1024 * 1024
      let slc = device.systemLevelCache / megabyte
      print("GPU system level cache: \(slc) MB")
      
      if device.memory % gigabyte == 0 {
        print("GPU memory: \(device.memory / gigabyte) GB")
      } else {
        let memory_gigabytes = Double(device.memory) / Double(gigabyte)
        print("GPU memory: \(rint(memory_gigabytes * 1e3) / 1e3) GB")
      }
      
      // Print the Metal GPU family
      let delta = device.family.rawValue - MTLGPUFamily.apple1.rawValue
      print("GPU family: Apple \(delta + 1)")
    } catch {
      // Handle any errors that may occur
      print("Error: \(error.localizedDescription)")
    }
  }
}

// Invoke the GPUInfo command
GPUInfoTool.main()
