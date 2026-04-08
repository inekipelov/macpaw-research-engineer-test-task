import Foundation

struct AppEnvironment {
    let registry: LocalLLMRegistry
    let chatClient: LLMChatClient

    static func live() -> AppEnvironment {
        let store = InstalledModelStore.live(paths: .live)

        return AppEnvironment(
            registry: LocalLLMRegistry.live(store: store),
            chatClient: .live()
        )
    }

    static let preview = AppEnvironment(
        registry: .preview,
        chatClient: .preview
    )
}
