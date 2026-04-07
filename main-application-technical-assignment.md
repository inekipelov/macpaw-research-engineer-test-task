# Technical Assignment 1 — Main Application Repository

## Goal

Build a minimal macOS CLI chat client that interacts with a separate Swift Package (`SPM LLM module`) to run local inference.

## Scope

- Platform: macOS
- App type: Swift CLI only
- Responsibility boundary:
  - **Main app** handles user interaction only
  - **No MLX/model logic** in this repository

## Functional Requirements

1. Implement a working chat flow:
   - receive user prompt
   - send prompt to SPM LLM module API
   - display assistant response as a stream (progressive output)
2. Keep conversation loop active until user exits.
3. Handle basic runtime errors from the SPM module and show user-friendly messages.
4. Support initial configuration input (e.g., model path/settings) via:
   - CLI args/env/config file.

## Non-Functional Requirements

1. Clear architecture and separation of concerns.
2. Async-safe request handling (`async/await`).
3. Minimal but clean code style and project structure.
4. No hardcoded model weights in repository.
5. Buildable with documented steps.

## Integration with SPM Module (Concrete Requirement)

Main app must connect the LLM module as a Swift Package dependency from this repository:

- `https://github.com/inekipelov/local-mlx-chat-core.git`

Integration must be done through SPM (`Package.swift`) and used directly by the CLI app for prompt submission and streaming response output.

## Deliverables

1. Source code in GitHub repo.
2. README with:
   - prerequisites
   - build/run instructions
   - configuration method
   - example usage
   - architecture overview and dependency boundary with SPM module.
