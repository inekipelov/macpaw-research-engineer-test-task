import Foundation
import LocalMLXChatCore

struct FakeFileSystem: FileSystem {
    let existingDirectories: Set<String>

    func directoryExists(at url: URL) -> Bool {
        existingDirectories.contains(url.path)
    }
}

final class InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Any]

    init(seed: [String: Any] = [:]) {
        self.storage = seed
    }

    func stringArray(forKey defaultName: String) -> [String]? {
        storage[defaultName] as? [String]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
}

final class FakeTerminal: TerminalIO {
    private var inputs: [String]
    private(set) var prompts: [String] = []
    private(set) var stdout = ""
    private(set) var stderr = ""

    init(inputs: [String]) {
        self.inputs = inputs
    }

    func readInput(prompt: String) -> String? {
        prompts.append(prompt)
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

final class FakeChatService: ChatService {
    private let streamsByPrompt: [String: [LocalModelStreamEvent]]
    private(set) var prompts: [String] = []

    init(streamsByPrompt: [String: [LocalModelStreamEvent]] = [:]) {
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

final class FakeChatServiceFactory: ChatServiceFactory {
    var servicesByModelPath: [String: FakeChatService]
    private(set) var requestedConfigurations: [CLIConfiguration] = []

    init(servicesByModelPath: [String: FakeChatService] = [:]) {
        self.servicesByModelPath = servicesByModelPath
    }

    func makeService(configuration: CLIConfiguration) -> ChatService {
        requestedConfigurations.append(configuration)
        return servicesByModelPath[configuration.modelPath.path] ?? FakeChatService()
    }
}

func makeConfiguration(
    modelPath: String = "/tmp/model",
    maxTokens: Int = 256,
    temperature: Double = 0.7,
    topP: Double = 0.95,
    seed: UInt64? = nil,
    contextWindowOverride: Int? = nil
) -> CLIConfiguration {
    CLIConfiguration(
        modelPath: URL(filePath: modelPath),
        generationOptions: GenerationOptions(
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            seed: seed
        ),
        contextWindowOverride: contextWindowOverride
    )
}
