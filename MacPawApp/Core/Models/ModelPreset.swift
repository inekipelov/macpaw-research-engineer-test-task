import Foundation
import LocalMLXChatCore

enum ModelPreset: String, Codable, CaseIterable, Equatable, Sendable {
    case fast
    case balanced
    case precise

    static let `default` = ModelPreset.balanced

    var title: String {
        switch self {
        case .fast:
            return "Fast"
        case .balanced:
            return "Balanced"
        case .precise:
            return "Precise"
        }
    }

    var summary: String {
        switch self {
        case .fast:
            return "Lower latency with shorter responses."
        case .balanced:
            return "General-purpose chat with the default package tuning."
        case .precise:
            return "More conservative sampling for consistency."
        }
    }

    var packagePreset: GenerationPreset {
        switch self {
        case .fast:
            return .fast
        case .balanced:
            return .balanced
        case .precise:
            return .precise
        }
    }
}
