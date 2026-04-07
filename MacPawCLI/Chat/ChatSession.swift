import Foundation
import LocalMLXChatCore

enum ChatSessionResult: Equatable {
    case close
    case exit
    case startupFailure
}

final class ChatSession {
    private let configuration: CLIConfiguration
    private let service: ChatService
    private let terminal: TerminalIO

    init(configuration: CLIConfiguration, service: ChatService, terminal: TerminalIO) {
        self.configuration = configuration
        self.service = service
        self.terminal = terminal
    }

    func run() async -> ChatSessionResult {
        terminal.writeLine("Chat ready for \(configuration.modelPath.lastPathComponent).")
        terminal.writeLine("Type /help for commands, close to change model, or /exit to quit.")

        var hasSuccessfulPrompt = false

        while let line = terminal.readInput(prompt: "you> ") {
            guard let command = ChatCommand.parse(line: line) else {
                continue
            }

            switch command {
            case .help:
                terminal.writeLine(CLIConfiguration.usageText)
            case .config:
                terminal.writeLine(configuration.formattedDescription)
            case .close:
                return .close
            case .exit:
                return .exit
            case .prompt(let prompt):
                let outcome = await handlePrompt(prompt, hasSuccessfulPrompt: hasSuccessfulPrompt)
                switch outcome {
                case .success:
                    hasSuccessfulPrompt = true
                case .continueSession:
                    continue
                case .closeSession:
                    return .close
                case .startupFailure:
                    return .startupFailure
                }
            }
        }

        return .exit
    }

    private func handlePrompt(_ prompt: String, hasSuccessfulPrompt: Bool) async -> PromptOutcome {
        var wroteAssistantPrefix = false

        for await event in service.stream(prompt: prompt) {
            switch event {
            case .chunk(let chunk):
                if !wroteAssistantPrefix {
                    terminal.write("assistant> ")
                    wroteAssistantPrefix = true
                }
                terminal.write(chunk)
            case .finished:
                if wroteAssistantPrefix {
                    terminal.write("\n")
                } else {
                    terminal.writeLine("assistant> ")
                }
                return .success
            case .failed(let error):
                if wroteAssistantPrefix {
                    terminal.write("\n")
                }

                switch error {
                case .invalidModelPath:
                    terminal.writeErrorLine(error.userFacingMessage)
                    return .closeSession
                case .modelLoadFailed:
                    terminal.writeLine(error.userFacingMessage)
                    return hasSuccessfulPrompt ? .closeSession : .startupFailure
                case .contextWindowExceeded, .inferenceFailed:
                    terminal.writeLine(error.userFacingMessage)
                    return .continueSession
                }
            }
        }

        return .continueSession
    }
}

private enum PromptOutcome {
    case success
    case continueSession
    case closeSession
    case startupFailure
}
