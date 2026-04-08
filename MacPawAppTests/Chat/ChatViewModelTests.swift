import Foundation
import Testing
@testable import MacPawApp

struct ChatViewModelTests {
    @Test
    func appendsStreamingTokensIntoSingleAssistantMessage() async throws {
        let client = LLMChatClient { _, _ in
            AsyncStream { continuation in
                continuation.yield(.started)
                continuation.yield(.token("Hi"))
                continuation.yield(.token(" there"))
                continuation.yield(.finished)
                continuation.finish()
            }
        }

        let model = makeInstalledModel()
        let viewModel = await MainActor.run { ChatViewModel(model: model, client: client) }
        await viewModel.send(prompt: "Hello")

        let messages = await MainActor.run { viewModel.messages }
        #expect(messages.count == 2)
        #expect(messages.first?.text == "Hello")
        #expect(messages.last?.text == "Hi there")
    }

    @Test
    func surfacesRuntimeFailuresWithoutCrashing() async throws {
        let client = LLMChatClient { _, _ in
            AsyncStream { continuation in
                continuation.yield(.started)
                continuation.yield(.failed("Generation failed"))
                continuation.finish()
            }
        }

        let model = makeInstalledModel()
        let viewModel = await MainActor.run { ChatViewModel(model: model, client: client) }
        await viewModel.send(prompt: "Hello")

        let errorMessage = await MainActor.run { viewModel.errorMessage }
        #expect(errorMessage == "Generation failed")
    }
}
