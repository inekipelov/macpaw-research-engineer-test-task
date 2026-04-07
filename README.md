# MacPaw Chat CLI

Minimal macOS CLI chat client that delegates local inference to the Swift package
[`LocalMLXChatCore`](https://github.com/inekipelov/local-mlx-chat-core.git).

## What Is Included

- Xcode CLI target: `MacPawCLI`
- Interactive terminal REPL with streaming output
- CLI-only runtime configuration
- Clear separation between terminal UX and MLX/model orchestration

The main app owns:
- command-line parsing
- terminal input/output
- slash commands
- user-facing error handling

The `LocalMLXChatCore` package owns:
- model loading
- prompt submission
- streaming token generation
- MLX-specific logic

## Prerequisites

- macOS 14 or newer
- Xcode 16.4+
- Apple Silicon machine
- A local MLX-compatible model directory on disk

## Open In Xcode

Open the Xcode project directly:

```bash
open MacPawCLI.xcodeproj
```

Run the `MacPawCLI` scheme from Xcode.

## Build

Build from Xcode or from the command line:

```bash
xcodebuild -project MacPawCLI.xcodeproj -scheme MacPawCLI build
```

## Run

Run from Xcode with the `MacPawCLI` scheme, or from the command line with the built executable.

Example command-line run after building:

```bash
/path/to/MacPawCLI \
  --model-path /Users/you/Models/Llama-3.2-1B-Instruct-4bit
```

You can also launch the CLI with no parameters. In that mode it will:

- show recently used model paths from local history
- let you pick a previous model
- or let you enter a new model path interactively

Optional flags:

- `--max-tokens <int>` default `256`
- `--temperature <double>` default `0.7`
- `--top-p <double>` default `0.95`
- `--seed <int>`
- `--context-window <int>`

Example:

```bash
/path/to/MacPawCLI \
  --model-path /Users/you/Models/Llama-3.2-1B-Instruct-4bit \
  --max-tokens 512 \
  --temperature 0.6 \
  --top-p 0.9 \
  --seed 7
```

## Runtime Behavior

On startup the CLI validates the model directory, then opens a REPL.

Available commands:

- `/help` shows usage and command help
- `/config` prints the effective runtime configuration
- `close` returns from the current chat session back to the model selection menu
- `/exit` exits the session

Exit shortcuts:

- `exit`
- `quit`
- EOF (`Ctrl-D`)

Each prompt is handled independently. The app does not store conversation history;
it simply forwards the current prompt to `LocalMLXChatCore` and streams chunks back
to the terminal.

The app does store model selection history between launches using `UserDefaults`, so
you can reopen the CLI and quickly return to recently used local models.

## Example Session

```text
MacPawChatCLI
Type /help for commands or /exit to quit.
you> List three benefits of local inference.
assistant> Lower latency, better privacy, and offline availability.
you> /config
modelPath: /Users/you/Models/Llama-3.2-1B-Instruct-4bit
maxTokens: 256
temperature: 0.7
topP: 0.95
seed: none
contextWindow: none
you> /exit
```

## Testing

The Xcode project includes a unit test target: `MacPawCLI-Tests`.

Run it from Xcode or from the command line:

```bash
xcodebuild -project MacPawCLI.xcodeproj -scheme MacPawCLI-Tests test
```

Automated coverage includes:

- launch option parsing and validation
- runtime configuration formatting
- model history persistence
- model selection coordinator flow
- chat command parsing
- chat session control flow, including `close`
