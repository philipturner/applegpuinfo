//
//  main.swift
//  
//
//  Created by Philip Turner on 3/19/23.
//

import AppleGPUInfo

// Generated using GPT-4. Methodology:
// - Feed the interface blurb from "AppleGPUInfo.swift" into the chat.
// - Ask it to write a simple command-line tool that extracts all the parameters
//   from the `AppleGPUDevice`, then outputs them using `print`. The tool should
//   be written in Swift.

// Auto-generated.

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
      
      // Print out some information about the device using its properties
//      print("GPU device name: \(device.mtlDevice.name)")
      
      // EDIT: Above is the only source of a compiler error that required
      // modification. `mtlDevice` is internal and can't be accessed this way.
      //
      // I changed the public API so that it provided a name.
      print("GPU device name: \(device.name)")
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