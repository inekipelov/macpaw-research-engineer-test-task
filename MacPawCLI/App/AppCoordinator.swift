import Foundation

final class AppCoordinator {
    private let launchOptions: LaunchOptions
    private let historyStore: ModelHistoryStore
    private let chatServiceFactory: ChatServiceFactory
    private let terminal: TerminalIO
    private let fileSystem: FileSystem

    init(
        launchOptions: LaunchOptions,
        historyStore: ModelHistoryStore,
        chatServiceFactory: ChatServiceFactory,
        terminal: TerminalIO,
        fileSystem: FileSystem = LocalFileSystem()
    ) {
        self.launchOptions = launchOptions
        self.historyStore = historyStore
        self.chatServiceFactory = chatServiceFactory
        self.terminal = terminal
        self.fileSystem = fileSystem
    }

    func run() async -> Int32 {
        terminal.writeLine("MacPawCLI")
        terminal.writeLine("Choose a model to begin chatting.")

        if let initialModelPath = launchOptions.initialModelPath {
            let result = await startChat(with: initialModelPath)
            if result == .exit {
                return 0
            }
        }

        while true {
            switch promptForModelSelection() {
            case .selectPath(let path):
                let result = await startChat(with: path)
                if result == .exit {
                    return 0
                }
            case .exit:
                return 0
            }
        }
    }

    private func startChat(with modelPath: URL) async -> ChatSessionResult {
        guard fileSystem.directoryExists(at: modelPath) else {
            historyStore.removeModelPath(modelPath.path)
            terminal.writeErrorLine(CLIConfigurationError.invalidModelPath(modelPath.path).message)
            return .close
        }

        historyStore.recordModelPath(modelPath.path)

        let configuration = launchOptions.configuration(for: modelPath)
        let session = ChatSession(
            configuration: configuration,
            service: chatServiceFactory.makeService(configuration: configuration),
            terminal: terminal
        )

        return await session.run()
    }

    private func promptForModelSelection() -> ModelSelectionAction {
        while true {
            let history = historyStore.modelPaths()
            terminal.writeLine(ModelSelectionMenu.text(for: history))

            guard let input = terminal.readInput(prompt: "select> ") else {
                return .exit
            }

            switch ModelSelectionMenu.parse(input, history: history) {
            case .selectHistoryPath(let path):
                return .selectPath(URL(filePath: path))
            case .enterNewPath:
                switch promptForNewModelPath() {
                case .selectPath(let url):
                    return .selectPath(url)
                case .exit:
                    return .exit
                case .back:
                    continue
                }
            case .exit:
                return .exit
            case nil:
                terminal.writeErrorLine("Invalid selection. Choose a number, `n`, or `exit`.")
            }
        }
    }

    private func promptForNewModelPath() -> NewModelPathAction {
        while true {
            guard let input = terminal.readInput(prompt: "model path> ") else {
                return .exit
            }

            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            switch trimmed.lowercased() {
            case "":
                terminal.writeErrorLine("Model path cannot be empty.")
            case "back", "cancel":
                return .back
            case "exit", "quit", "/exit":
                return .exit
            default:
                let url = URL(filePath: trimmed)
                guard fileSystem.directoryExists(at: url) else {
                    terminal.writeErrorLine(CLIConfigurationError.invalidModelPath(url.path).message)
                    return .back
                }
                return .selectPath(url)
            }
        }
    }
}

private enum ModelSelectionAction: Equatable {
    case selectPath(URL)
    case exit
}

private enum NewModelPathAction: Equatable {
    case selectPath(URL)
    case back
    case exit
}
