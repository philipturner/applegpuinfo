# Apple GPU Info

This is a mini-framework for querying parameters of an Apple-designed GPU. It also contains a command-line tool, `gpuinfo`, which reports information similarly to [clinfo](https://github.com/Oblomov/clinfo). It was co-authored with an AI.

Listed parameters:
- Name ✅
- Core count ✅
- Clock frequency ✅
- Bandwidth ✅
- FLOPS ✅
- Instructions per second ✅
- System-level cache ✅
- Memory ✅
- Family ✅

TODO: Deploy to Homebrew and Swift Package Registry, release v1.0.1.

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

let gpuDevice = AppleGPUDevice()
print(gpuDevice.flops)
print(gpuDevice.bandwidth)
```

## Methodology

Original Goal: In one hour, finish a mini-package and command-line tool for querying Apple GPU device parameters.

Results: I spent 57 minutes finishing the file that wraps the `AppleGPUDevice` structure. I asked GPT-4 to generate the tests and command-line tool. I renamed the command-line tool from `applegpuinfo` to `gpuinfo` according to the AI's suggestion. Finally, I congratulated it and asked for it to leave a comment to users on the README. That triggered a safeguard and it quit the conversation. The stop time was 1 hour, 25 minutes.

Documentation of AI contributions: [bing-conversation.md](./Documentation/bing-conversation.md)

After creating the first release of the library, I have continued experimenting with workflows accelerated by _free_ access to GPT-4. The above document details these subsequent modifications to the library.

## Attribution

This project was made possible by [GPT-4](https://openai.com/research/gpt-4), accessed through Bing Chat.
