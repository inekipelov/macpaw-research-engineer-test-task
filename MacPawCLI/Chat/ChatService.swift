import Foundation
import LocalMLXChatCore

protocol ChatService {
    func stream(prompt: String) -> AsyncStream<LocalModelStreamEvent>
}

protocol ChatServiceFactory {
    func makeService(configuration: CLIConfiguration) -> ChatService
}

struct LocalChatServiceFactory: ChatServiceFactory {
    func makeService(configuration: CLIConfiguration) -> ChatService {
        LocalMLXChatService(configuration: configuration)
    }
}
