# Apple GPU Info

This is a mini-framework for querying parameters of an Apple-designed GPU. It also contains a command-line tool, `gpuinfo`, which reports information similarly to [clinfo](https://github.com/Oblomov/clinfo). It was co-authored with an AI.

## Features

Listed parameters:
- Name ✅
- Core count ✅
- Clock frequency ✅
- Bandwidth ✅
- FLOPS (FP32 operations per second) ✅
- IPS (shader instructions per second) ✅
- System-level cache ✅
- Memory ✅
- Family ✅

Interfaces:
- Swift module
- C bindings
- Command-line tool

Recognized devices:
- A7 - A16
- M1 - M1 Ultra
- M2 - M2 Max
- Future devices treated like the closest existing analog (e.g. A17 like A16)

## Usage

One way to use this library is from the command-line:

```
git clone https://github.com/philipturner/applegpuinfo
cd applegpuinfo
swift run gpuinfo list

# Sample output
GPU name: Apple M1 Max
GPU core count: 32
GPU clock frequency: 1.296 GHz
GPU bandwidth: 409.6 GB/s
GPU FLOPS: 10.617 TFLOPS
GPU IPS: 5.308 TIPS
GPU system level cache: 48 MB
GPU memory: 32 GB
GPU family: Apple 7
```

You can also use it directly from Swift:

```swift
// Inside package manifest
dependencies: [
  // Dependencies declare other packages that this package depends on.
  .package(url: "https://github.com/philipturner/applegpuinfo", branch: "main"),
],

// Inside source code
import AppleGPUInfo

let device = try GPUInfoDevice()
print(device.flops)
print(device.bandwidth)
```

## Methodology

Original Goal: In one hour, finish a mini-package and command-line tool for querying Apple GPU device parameters.

Results: I spent 57 minutes finishing the file that wraps the `AppleGPUDevice` structure. I asked GPT-4 to generate the tests and command-line tool. I renamed the command-line tool from `applegpuinfo` to `gpuinfo` according to the AI's suggestion. Finally, I congratulated it and asked for it to leave a comment to users on the README. That triggered a safeguard and it quit the conversation. The stop time was 1 hour, 25 minutes.

Documentation of AI contributions: [bing-conversation.md](./Documentation/bing-conversation.md)

After creating the first release of the library, I have continued experimenting with workflows accelerated by _free_ access to GPT-4. The above document details these subsequent modifications to the library.

## Testing

This framework is confirmed to work on the following devices. If anyone wishes to contribute to this list, please paste the output of `gpuinfo` into a new GitHub issue. Different variations of the same chip (e.g. different cores or memory) are welcome.

| Production Year | Chip | Cores | SLC | Memory | Bandwidth | TFLOPS |
| --------------- | --- | ----- | ------ | ---- | --------- | ------ |
| 2017 | A10X     | 12 | 0 MB | 4 GB | 68.2 GB/s | 0.768 |
| 2021 | A15      | 5  | 32 MB | 5.6 GB | 34.1 GB/s | 1.789 |
| 2021 | M1 Pro   | 16 | 24 MB | 32 GB | 204.8 GB/s | 5.308 |
| 2021 | M1 Max   | 32 | 48 MB | 32 GB | 409.6 GB/s | 10.617 |
| 2022 | M1 Ultra | 48 | 96 MB | 64 GB | 819.2 GB/s | 15.925 |
| 2023 | M2 Pro   | 19 | 24 MB | 32 GB | 204.8 GB/s | 6.800 |

## Attribution

This project was made possible by [GPT-4](https://openai.com/research/gpt-4), accessed through Bing Chat.
