# Apple GPU Info

This is a mini-framework for querying parameters of an Apple-designed GPU. It also contains a command-line tool, `gpuinfo`, which reports information similarly to [clinfo](https://github.com/Oblomov/clinfo). It was co-authored with an AI.

Listed parameters:
- Name ✅
- Cores ✅
- Clock frequency ✅
- Bandwidth ✅
- FLOPS ✅
- System-level cache ✅
- Memory ✅
- Family: ✅

TODO: Deploy to Homebrew, port to iOS.

## Methodology

Original Goal: In one hour, finish a mini-package and command-line tool for querying Apple GPU device parameters.

Results: I spent 57 minutes finishing the file that wraps the `AppleGPUDevice` structure. I asked GPT-4 to generate the tests and command-line tool. I renamed the command-line tool from `applegpuinfo` to `gpuinfo` according to the AI's suggestion. Finally, I congratulated it and asked for it to leave a comment to users on the README. That triggered a safeguard and it quit the conversation. The stop time was 1 hour, 25 minutes.

Methodology: [bing-conversation.md](./Documentation/bing-conversation.md)

## Attribution

This project was made possible by [GPT-4](https://openai.com/research/gpt-4), accessed through Bing Chat.
