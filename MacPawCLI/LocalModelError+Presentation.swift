import Foundation
import LocalMLXChatCore

extension LocalModelError {
    var userFacingMessage: String {
        switch self {
        case .invalidModelPath(let path):
            return "Model path is invalid or missing: \(path)"
        case .modelLoadFailed(let message):
            return "Model failed to load: \(message)"
        case .inferenceFailed(let message):
            return "Generation failed: \(message)"
        case .contextWindowExceeded(let promptTokens, let requestedOutputTokens, let availableContextWindow):
            return """
            Prompt exceeds the available context window (prompt: \(promptTokens), requested output: \(requestedOutputTokens), available: \(availableContextWindow)).
            """
        }
    }
}
