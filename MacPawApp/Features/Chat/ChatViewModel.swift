import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    let model: InstalledModel

    @Published var messages: [ChatMessage] = []
    @Published var prompt = ""
    @Published var isStreaming = false
    @Published var errorMessage: String?

    private let client: LLMChatClient
    private var streamTask: Task<Void, Never>?

    init(model: InstalledModel, client: LLMChatClient) {
        self.model = model
        self.client = client
    }

    deinit {
        streamTask?.cancel()
    }

    func sendCurrentPrompt() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, !isStreaming else {
            return
        }

        prompt = ""
        cancelStreaming()
        streamTask = Task { [weak self] in
            await self?.beginSend(prompt: trimmedPrompt)
        }
    }

    func send(prompt: String) async {
        cancelStreaming()
        await beginSend(prompt: prompt)
    }

    func cancelStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    private func beginSend(prompt: String) async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            return
        }

        errorMessage = nil
        isStreaming = true
        messages.append(ChatMessage(role: .user, text: trimmedPrompt))
        messages.append(ChatMessage(role: .assistant, text: ""))

        do {
            let stream = try await client.streamReply(prompt: trimmedPrompt, model: model)

            for await event in stream {
                switch event {
                case .started:
                    break
                case .token(let token):
                    appendAssistantToken(token)
                case .finished:
                    isStreaming = false
                case .failed(let message):
                    errorMessage = message
                    isStreaming = false
                }
            }
        } catch is CancellationError {
            isStreaming = false
        } catch {
            errorMessage = error.localizedDescription
            isStreaming = false
        }
    }

    private func appendAssistantToken(_ token: String) {
        guard let lastIndex = messages.indices.last, messages[lastIndex].role == .assistant else {
            messages.append(ChatMessage(role: .assistant, text: token))
            return
        }

        messages[lastIndex].text.append(token)
    }
}
