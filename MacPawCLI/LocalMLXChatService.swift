import Foundation
import LocalMLXChatCore

final class LocalMLXChatService: ChatService {
    private let client: LocalModelClient

    init(configuration: CLIConfiguration) {
        self.client = LocalModelClient(configuration: configuration.localModelConfiguration)
    }

    func stream(prompt: String) -> AsyncStream<LocalModelStreamEvent> {
        client.stream(prompt: prompt)
    }
}
