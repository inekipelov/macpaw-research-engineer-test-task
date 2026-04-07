import Foundation
import Testing

@Suite("AppCoordinator")
struct AppCoordinatorTests {
    @Test("No args with empty history accepts a new model path")
    func noArgsWithEmptyHistoryAcceptsNewModelPath() async throws {
        let terminal = FakeTerminal(inputs: ["n", "/models/new", "close", "exit"])
        let history = ModelHistoryStore(
            keyValueStore: InMemoryKeyValueStore(),
            historyLimit: 5
        )
        let factory = FakeChatServiceFactory()
        let coordinator = AppCoordinator(
            launchOptions: try LaunchOptions.make(arguments: []),
            historyStore: history,
            chatServiceFactory: factory,
            terminal: terminal,
            fileSystem: FakeFileSystem(existingDirectories: ["/models/new"])
        )

        let exitCode = await coordinator.run()

        #expect(exitCode == 0)
        #expect(history.modelPaths() == ["/models/new"])
        #expect(factory.requestedConfigurations.map(\.modelPath.path) == ["/models/new"])
    }

    @Test("History is shown as numbered menu")
    func historyIsShownAsNumberedMenu() async throws {
        let terminal = FakeTerminal(inputs: ["exit"])
        let history = ModelHistoryStore(
            keyValueStore: InMemoryKeyValueStore(seed: [ModelHistoryStore.historyKey: ["/models/one", "/models/two"]]),
            historyLimit: 5
        )
        let coordinator = AppCoordinator(
            launchOptions: try LaunchOptions.make(arguments: []),
            historyStore: history,
            chatServiceFactory: FakeChatServiceFactory(),
            terminal: terminal,
            fileSystem: FakeFileSystem(existingDirectories: ["/models/one", "/models/two"])
        )

        let exitCode = await coordinator.run()

        #expect(exitCode == 0)
        #expect(terminal.stdout.contains("1. /models/one"))
        #expect(terminal.stdout.contains("2. /models/two"))
        #expect(terminal.stdout.contains("n. Enter new model path"))
    }

    @Test("Invalid stored path is removed and menu continues")
    func invalidStoredPathIsRemovedAndMenuContinues() async throws {
        let terminal = FakeTerminal(inputs: ["1", "exit"])
        let history = ModelHistoryStore(
            keyValueStore: InMemoryKeyValueStore(seed: [ModelHistoryStore.historyKey: ["/models/missing"]]),
            historyLimit: 5
        )
        let coordinator = AppCoordinator(
            launchOptions: try LaunchOptions.make(arguments: []),
            historyStore: history,
            chatServiceFactory: FakeChatServiceFactory(),
            terminal: terminal,
            fileSystem: FakeFileSystem(existingDirectories: [])
        )

        let exitCode = await coordinator.run()

        #expect(exitCode == 0)
        #expect(history.modelPaths().isEmpty)
        #expect(terminal.stderr.contains("/models/missing"))
    }

    @Test("Choosing a model from history enters chat")
    func choosingAModelFromHistoryEntersChat() async throws {
        let terminal = FakeTerminal(inputs: ["1", "close", "exit"])
        let history = ModelHistoryStore(
            keyValueStore: InMemoryKeyValueStore(seed: [ModelHistoryStore.historyKey: ["/models/one"]]),
            historyLimit: 5
        )
        let factory = FakeChatServiceFactory()
        let coordinator = AppCoordinator(
            launchOptions: try LaunchOptions.make(arguments: []),
            historyStore: history,
            chatServiceFactory: factory,
            terminal: terminal,
            fileSystem: FakeFileSystem(existingDirectories: ["/models/one"])
        )

        let exitCode = await coordinator.run()

        #expect(exitCode == 0)
        #expect(factory.requestedConfigurations.map(\.modelPath.path) == ["/models/one"])
    }

    @Test("Close from chat returns to model picker")
    func closeFromChatReturnsToModelPicker() async throws {
        let terminal = FakeTerminal(inputs: ["1", "close", "exit"])
        let history = ModelHistoryStore(
            keyValueStore: InMemoryKeyValueStore(seed: [ModelHistoryStore.historyKey: ["/models/one"]]),
            historyLimit: 5
        )
        let coordinator = AppCoordinator(
            launchOptions: try LaunchOptions.make(arguments: []),
            historyStore: history,
            chatServiceFactory: FakeChatServiceFactory(),
            terminal: terminal,
            fileSystem: FakeFileSystem(existingDirectories: ["/models/one"])
        )

        _ = await coordinator.run()

        #expect(terminal.prompts.filter { $0 == "select> " }.count == 2)
    }

    @Test("Exit from chat exits the process")
    func exitFromChatExitsTheProcess() async throws {
        let terminal = FakeTerminal(inputs: ["1", "/exit"])
        let history = ModelHistoryStore(
            keyValueStore: InMemoryKeyValueStore(seed: [ModelHistoryStore.historyKey: ["/models/one"]]),
            historyLimit: 5
        )
        let coordinator = AppCoordinator(
            launchOptions: try LaunchOptions.make(arguments: []),
            historyStore: history,
            chatServiceFactory: FakeChatServiceFactory(),
            terminal: terminal,
            fileSystem: FakeFileSystem(existingDirectories: ["/models/one"])
        )

        let exitCode = await coordinator.run()

        #expect(exitCode == 0)
        #expect(terminal.prompts.filter { $0 == "select> " }.count == 1)
    }
}
