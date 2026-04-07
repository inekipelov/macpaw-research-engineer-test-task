import XCTest
import LocalMLXChatCore
@testable import MacPawChatCLI

final class ChatSessionTests: XCTestCase {
    func testIgnoresBlankLines() async {
        let terminal = FakeTerminal(inputs: ["", "   ", "/exit"])
        let service = FakeChatService(streamsByPrompt: [:])
        let configuration = makeConfiguration()
        let session = ChatSession(configuration: configuration, service: service, terminal: terminal)

        let exitCode = await session.run()

        XCTAssertEqual(exitCode, 0)
        XCTAssertTrue(service.prompts.isEmpty)
    }

    func testStreamsChunksAndAppendsTrailingNewline() async {
        let terminal = FakeTerminal(inputs: ["Hello", "/exit"])
        let service = FakeChatService(
            streamsByPrompt: [
                "Hello": [.chunk("Hi"), .chunk(" there"), .finished]
            ]
        )
        let configuration = makeConfiguration()
        let session = ChatSession(configuration: configuration, service: service, terminal: terminal)

        let exitCode = await session.run()

        XCTAssertEqual(exitCode, 0)
        XCTAssertTrue(terminal.stdout.contains("assistant> Hi there\n"))
    }

    func testInferenceFailureDoesNotCrashSession() async {
        let terminal = FakeTerminal(inputs: ["Hello", "/exit"])
        let service = FakeChatService(
            streamsByPrompt: [
                "Hello": [.failed(.inferenceFailed("decoder stalled"))]
            ]
        )
        let configuration = makeConfiguration()
        let session = ChatSession(configuration: configuration, service: service, terminal: terminal)

        let exitCode = await session.run()

        XCTAssertEqual(exitCode, 0)
        XCTAssertTrue(terminal.stdout.contains("Generation failed: decoder stalled"))
    }

    func testConfigCommandPrintsEffectiveRuntimeConfiguration() async {
        let terminal = FakeTerminal(inputs: ["/config", "/exit"])
        let service = FakeChatService(streamsByPrompt: [:])
        let configuration = makeConfiguration()
        let session = ChatSession(configuration: configuration, service: service, terminal: terminal)

        let exitCode = await session.run()

        XCTAssertEqual(exitCode, 0)
        XCTAssertTrue(terminal.stdout.contains("modelPath: /tmp/model"))
        XCTAssertTrue(terminal.stdout.contains("maxTokens: 256"))
        XCTAssertTrue(terminal.stdout.contains("temperature: 0.7"))
        XCTAssertTrue(terminal.stdout.contains("topP: 0.95"))
    }
}

private func makeConfiguration() -> CLIConfiguration {
    CLIConfiguration(
        modelPath: URL(filePath: "/tmp/model"),
        generationOptions: GenerationOptions(
            maxTokens: 256,
            temperature: 0.7,
            topP: 0.95,
            seed: nil
        ),
        contextWindowOverride: nil
    )
}

final class FakeChatService: ChatService {
    let streamsByPrompt: [String: [LocalModelStreamEvent]]
    private(set) var prompts: [String] = []

    init(streamsByPrompt: [String: [LocalModelStreamEvent]]) {
        self.streamsByPrompt = streamsByPrompt
    }

    func stream(prompt: String) -> AsyncStream<LocalModelStreamEvent> {
        prompts.append(prompt)
        let events = streamsByPrompt[prompt] ?? [.finished]
        return AsyncStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }
}

private final class FakeTerminal: TerminalIO {
    private var inputs: [String]
    var stdout = ""
    var stderr = ""

    init(inputs: [String]) {
        self.inputs = inputs
    }

    func readInput(prompt: String) -> String? {
        guard !inputs.isEmpty else { return nil }
        return inputs.removeFirst()
    }

    func write(_ text: String) {
        stdout += text
    }

    func writeLine(_ text: String) {
        stdout += text + "\n"
    }

    func writeErrorLine(_ text: String) {
        stderr += text + "\n"
    }
}

struct FakeFileSystem: FileSystem {
    let existingDirectories: Set<String>

    func directoryExists(at url: URL) -> Bool {
        existingDirectories.contains(url.path)
    }
}
