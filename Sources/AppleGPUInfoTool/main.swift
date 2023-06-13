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
      let error = setenv("GPUINFO_LOG_LEVEL", "1", 1)
      if error != 0 {
        print("`setenv` failed with error code '\(error)'.")
      }
      _ = try GPUInfoDevice()
    } catch {
      // Handle any errors that may occur
      print("Error: \(error.localizedDescription)")
    }
  }
}

// Invoke the GPUInfo command
GPUInfoTool.main()
