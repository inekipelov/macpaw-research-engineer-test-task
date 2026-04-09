# MacPawApp

Minimal macOS SwiftUI app for running local chats with a model provided by
[`LocalMLXChatCore`](https://github.com/inekipelov/local-mlx-chat-core.git).

## What The App Does

- install a local LLM by selecting an existing model folder on disk
- keep a local history of installed and recently used models
- store a response preset per model:
  - `fast`
  - `balanced`
  - `precise`
- open an in-app chat named after the selected model
- stream assistant output progressively in the chat UI

The app owns:

- SwiftUI user interface
- local persistence
- model selection and preset editing
- chat state and streaming presentation

`LocalMLXChatCore` owns:

- model loading
- prompt submission
- MLX-backed local inference
- stream generation events

## Requirements

- macOS 14 or newer
- Xcode 16.4+
- Apple Silicon
- an already-downloaded local model directory on disk

## Open In Xcode

```bash
open MacPawCLI.xcodeproj
```

Use the `MacPawApp` scheme for the app and `MacPawAppTests` for tests.

## Build

```bash
xcodebuild -project MacPawCLI.xcodeproj -scheme MacPawApp build
```

## Test

```bash
xcodebuild -project MacPawCLI.xcodeproj -scheme MacPawAppTests test
```

## User Flow

1. Launch the app.
2. Click `Install Local Model…`.
3. Choose an already-downloaded model folder.
4. Choose a response preset for that model.
5. Click `Open Chat`.
6. Send prompts and receive a progressively streamed response.

Installed models and their selected presets are stored locally in Application Support.
No model weights are committed to the repository.

## Architecture

- `MacPawApp/Features/Library` handles installed model history
- `MacPawApp/Features/Setup` handles per-model advanced settings
- `MacPawApp/Features/Chat` handles the in-app conversation experience
- `MacPawApp/Core/Persistence` stores installed model records as JSON
- `MacPawApp/Core/Services/LLMChatClient` bridges the SwiftUI app to `LocalMLXChatCore`
