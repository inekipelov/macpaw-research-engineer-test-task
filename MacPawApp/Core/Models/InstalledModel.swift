import Foundation

struct ModelParameters: Codable, Equatable, Sendable {
    var maxTokens: Int
    var temperature: Double
    var topP: Double
    var seed: Int?
    var contextWindow: Int?

    static let defaults = ModelParameters(
        maxTokens: 256,
        temperature: 0.7,
        topP: 0.95,
        seed: nil,
        contextWindow: nil
    )
}

struct InstalledModel: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var displayName: String
    var modelPath: String
    var lastUsedAt: Date
    var parameters: ModelParameters
}
