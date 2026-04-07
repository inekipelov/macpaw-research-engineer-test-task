import Foundation
import LocalMLXChatCore

protocol ChatService {
    func stream(prompt: String) -> AsyncStream<LocalModelStreamEvent>
}
