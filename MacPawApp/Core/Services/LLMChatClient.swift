import Foundation
import LocalMLXChatCore

enum ChatStreamEvent: Equatable, Sendable {
    case started
    case token(String)
    case finished
    case failed(String)
}

struct LLMChatClient {
    private let streamReplyOperation: @Sendable (String, InstalledModel) async throws -> AsyncStream<ChatStreamEvent>

    init(streamReply: @escaping @Sendable (String, InstalledModel) async throws -> AsyncStream<ChatStreamEvent>) {
        self.streamReplyOperation = streamReply
    }

    func streamReply(prompt: String, model: InstalledModel) async throws -> AsyncStream<ChatStreamEvent> {
        try await streamReplyOperation(prompt, model)
    }

    static func live() -> LLMChatClient {
        LLMChatClient { prompt, model in
            let client = LocalModelClient(
                configuration: LocalModelConfiguration(
                    modelPath: URL(filePath: model.modelPath),
                    generationPreset: model.generationPreset.packagePreset
                )
            )

            let upstream = client.stream(prompt: prompt)
            let (stream, continuation) = AsyncStream.makeStream(of: ChatStreamEvent.self)
            let relayTask = Task {
                continuation.yield(.started)

                for await event in upstream {
                    switch event {
                    case .chunk(let chunk):
                        continuation.yield(.token(chunk))
                    case .finished:
                        continuation.yield(.finished)
                        continuation.finish()
                    case .failed(let error):
                        continuation.yield(.failed(message(for: error)))
                        continuation.finish()
                    }
                }
            }

            continuation.onTermination = { _ in
                relayTask.cancel()
            }

            return stream
        }
    }

    static let preview = LLMChatClient { _, _ in
        AsyncStream { continuation in
            continuation.yield(.started)
            continuation.yield(.finished)
            continuation.finish()
        }
    }

    private static func message(for error: LocalModelError) -> String {
        switch error {
        case .invalidModelPath(let path):
            return "Model folder is invalid: \(path)"
        case .modelLoadFailed(let message):
            return "Failed to load model: \(message)"
        case .inferenceFailed(let message):
            return "Generation failed: \(message)"
        case .contextWindowExceeded(let promptTokens, let requestedOutputTokens, let availableContextWindow):
            return "Context window exceeded (\(promptTokens) prompt tokens + \(requestedOutputTokens) output tokens > \(availableContextWindow))."
        }
    }
}
