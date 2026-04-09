# MacPaw Test Task: Local macOS Chat App

Minimal macOS SwiftUI chat application for local on-device text generation with Apple MLX.

This submission is intentionally split into two parts, matching the test task:

- `MacPawApp`: the macOS application layer responsible for UI, model selection, persistence, and chat presentation
- `LocalMLXChatCore`: a separate Swift Package dependency responsible for model loading, prompt preparation, and local generation

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.1+-F05138?logo=swift&logoColor=white" alt="Swift 6.1+"></a>
  <a href="https://developer.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-14.0+-000000?logo=apple" alt="macOS 14.0+"></a>
  <a href="https://developer.apple.com/xcode/"><img src="https://img.shields.io/badge/Xcode-16.4+-147EFB?logo=xcode&logoColor=white" alt="Xcode 16.4+"></a>
  <a href="https://developer.apple.com/apple-silicon/"><img src="https://img.shields.io/badge/Apple%20Silicon-Required-000000?logo=apple" alt="Apple Silicon required"></a>
  <a href="#manual-test-instructions"><img src="https://img.shields.io/badge/Manual%20Verification-Included-5C2D91" alt="Manual verification included"></a>
</p>

## Summary

This project implements a lightweight GUI chat app for macOS that works with an already-downloaded local MLX-compatible model directory.

The app provides:

- installation of a local model folder from disk
- local persistence of installed models and last-used ordering
- per-model response presets:
  - `fast`
  - `balanced`
  - `precise`
- a simple chat flow with prompt input and assistant output
- streaming assistant responses, so text appears progressively while tokens are generated
- a chat close action that returns to setup, allowing the preset to be changed for the selected model

The repository does not include model weights.

## Requirement Coverage

The original assignment asks for:

> Build a simple macOS chat app (CLI or GUI) that uses a local LLM via Apple's MLX framework.

This submission implements a GUI macOS app in SwiftUI.

| Task requirement | Implementation in this repository |
| --- | --- |
| Main app with input/output UI | `MacPawApp` SwiftUI app with sidebar, setup screen, and chat screen |
| Separate Swift Package for LLM logic | `LocalMLXChatCore` is consumed as a standalone Swift Package dependency |
| Main app handles UI only | UI, local persistence, model selection, and chat presentation stay in `MacPawApp` |
| Package handles model loading, prompt preparation, and generation | `LocalMLXChatCore` owns local model configuration, loading, and MLX-backed generation |
| Minimal but working chat flow | Install model, choose preset, open chat, send prompt, receive response |
| Optional streaming | Implemented via `AsyncStream` and incremental UI token rendering |
| README with build/run/setup/testing instructions | This file |

## Architecture

### App layer: `MacPawApp`

The app target owns everything that is product-facing:

- `MacPawApp/Features/Library`
  - installs, selects, lists, and removes local model folders
- `MacPawApp/Features/Setup`
  - configures the response preset for the selected model
- `MacPawApp/Features/Chat`
  - accepts prompts, displays streamed responses, and shows runtime errors
- `MacPawApp/Core/Persistence`
  - stores installed models in a local JSON file under Application Support
- `MacPawApp/Core/Services`
  - bridges app state to the Swift Package and isolates app-facing errors/events

### LLM layer: `LocalMLXChatCore`

The package dependency owns the inference side:

- local model configuration
- model loading from a filesystem directory
- prompt submission
- one-shot generation and streaming generation
- MLX-backed local inference
- structured app-facing errors

Current integration target: `LocalMLXChatCore 0.2.1`.

In the app target, `LLMChatClient` is the adapter between SwiftUI and the package API.

For this submission, the LLM module is kept separate from the app as an external Swift Package dependency rather than an in-repo local package target.

## Project Structure

```text
MacPawCLI.xcodeproj
MacPawApp/
  App/
  Core/
    Models/
    Persistence/
    Services/
  Features/
    Library/
    Setup/
    Chat/
    Root/
MacPawAppTests/
```

Main schemes:

- `MacPawApp`: application target
- `MacPawAppTests`: automated test target

## Requirements

- macOS 14.0 or newer
- Xcode 16.4 or newer
- Apple Silicon Mac
- an already-downloaded MLX-compatible model directory on disk

For the quickest review path, use a small instruct model such as an MLX-compatible Llama 3.2 1B or 3B variant.

Example model directory:

```text
/Users/you/Models/Llama-3.2-1B-Instruct-4bit
```

A usable model folder should contain the files expected by `mlx-swift-lm`, typically including:

- one or more `*.safetensors` files
- tokenizer files
- model configuration files
- chat template or generation metadata when provided by the model package

No API keys or network access are required to use the app once the model is present locally.

## Open In Xcode

```bash
open MacPawCLI.xcodeproj
```

## Build

```bash
xcodebuild -project MacPawCLI.xcodeproj -scheme MacPawApp build
```

## Run

Use Xcode:

1. Open `MacPawCLI.xcodeproj`
2. Select the `MacPawApp` scheme
3. Build and run the app

On launch, the app opens a single window named `MacPaw Chat`.

## Automated Verification

Build:

```bash
xcodebuild -project MacPawCLI.xcodeproj -scheme MacPawApp build
```

Test:

```bash
xcodebuild -project MacPawCLI.xcodeproj -scheme MacPawAppTests test
```

The automated tests cover:

- preset-only model persistence
- library model installation and ordering
- root flow and chat open/close navigation
- setup view model preset editing
- chat streaming aggregation and runtime error handling
- registry behavior, including recovery from unreadable local store contents

## Manual Test Instructions

These are the manual checks I would expect a reviewer to run for the test task.

### 1. First launch

1. Run the app.
2. Verify that the sidebar shows an empty-state message when no models are installed.

Expected result:

- the app opens successfully
- the UI is minimal and functional
- no model is selected yet

### 2. Install a valid local model

1. Click `Install Local Model…`
2. Choose an already-downloaded MLX-compatible model directory

Expected result:

- the model appears in the sidebar
- the model becomes selected
- the setup screen opens for that model
- the setup screen shows a `Response style` picker with `Fast`, `Balanced`, and `Precise`

### 3. Open chat and verify streaming

1. Leave the preset at `Balanced` or choose any preset
2. Click `Open Chat`
3. Send a prompt such as:

```text
Explain what Swift Package Manager does in two short paragraphs.
```

Expected result:

- the chat screen opens for the selected model
- the user message appears immediately
- the assistant response appears progressively rather than all at once
- the app remains responsive while output is being generated

This confirms the optional streaming part of the assignment is implemented.

### 4. Change preset after closing chat

1. While in chat, click `Close Chat`
2. Verify that the app returns to the setup screen for the same model
3. Change the response style
4. Click `Open Chat` again

Expected result:

- closing chat does not deselect the model
- the preset can be changed without reinstalling the model
- reopening chat uses the updated preset for that model

### 5. Remove a model

1. Select an installed model in the sidebar
2. Click `Remove`

Expected result:

- the model is removed from local persistence
- it disappears from the sidebar
- if it was the last model, the empty state returns

### 6. Error handling with an invalid model folder

Two useful negative-path checks:

1. Install a directory that exists but is not a valid MLX model folder, then try to chat
2. Install a valid model, then move or delete the folder outside the app and try to chat again

Expected result:

- the app surfaces an error message instead of crashing
- failures are shown in the UI when model loading or inference cannot proceed

### 7. Persistence across relaunch

1. Install a model
2. Change its preset
3. Quit the app
4. Launch the app again

Expected result:

- the installed model list is restored
- the selected preset is restored for that model
- the app does not require reinstallation of the model entry

Persisted app data is stored locally at:

```text
~/Library/Application Support/MacPawApp/installed-models.json
```

## How It Works

At runtime, the flow is:

1. the user installs a local model folder from disk
2. the app stores an `InstalledModel` record with the selected preset
3. opening chat builds a `LocalModelConfiguration` using:
   - the selected model path
   - the selected `GenerationPreset`
4. `LLMChatClient` creates a `LocalModelClient` from `LocalMLXChatCore`
5. the package streams generation events
6. the app relays those events into SwiftUI and appends incoming tokens to the visible assistant message

This keeps MLX-specific orchestration inside the package and keeps the app target focused on user interaction and state management.

## Notes And Assumptions

- This project is intentionally minimal. The focus of the assignment is architecture, separation of concerns, and code quality rather than UI polish.
- The app assumes the reviewer already has a local MLX-compatible model folder.
- The app does not download model weights.
- Conversation history is kept in-memory for the current chat session; installed model metadata is persisted locally.
- The current UI is preset-driven rather than exposing raw generation parameters directly.
