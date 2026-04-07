import Foundation
import LocalMLXChatCore

final class ChatSession {
    private let configuration: CLIConfiguration
    private let service: ChatService
    private let terminal: TerminalIO

    init(configuration: CLIConfiguration, service: ChatService, terminal: TerminalIO) {
        self.configuration = configuration
        self.service = service
        self.terminal = terminal
    }

    func run() async -> Int32 {
        terminal.writeLine("MacPawChatCLI")
        terminal.writeLine("Type /help for commands or /exit to quit.")

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
            case .exit:
                return 0
            case .prompt(let prompt):
                let outcome = await handlePrompt(prompt, hasSuccessfulPrompt: hasSuccessfulPrompt)
                switch outcome {
                case .success:
                    hasSuccessfulPrompt = true
                case .continueSession:
                    continue
                case .exitFailure:
                    return 1
                }
            }
        }

        return 0
    }

    private func handlePrompt(_ prompt: String, hasSuccessfulPrompt: Bool) async -> PromptOutcome {
        var didWriteAssistantPrefix = false

        for await event in service.stream(prompt: prompt) {
            switch event {
            case .chunk(let chunk):
                if !didWriteAssistantPrefix {
                    terminal.write("assistant> ")
                    didWriteAssistantPrefix = true
                }
                terminal.write(chunk)
            case .finished:
                if didWriteAssistantPrefix {
                    terminal.write("\n")
                } else {
                    terminal.writeLine("assistant> ")
                }
                return .success
            case .failed(let error):
                if didWriteAssistantPrefix {
                    terminal.write("\n")
                }

                switch error {
                case .invalidModelPath:
                    terminal.writeErrorLine(error.userFacingMessage)
                    return .exitFailure
                case .modelLoadFailed:
                    terminal.writeLine(error.userFacingMessage)
                    return hasSuccessfulPrompt ? .continueSession : .exitFailure
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
    case exitFailure
}
