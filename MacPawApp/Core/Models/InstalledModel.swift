import Foundation

struct InstalledModel: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var displayName: String
    var modelPath: String
    var lastUsedAt: Date
    var generationPreset: ModelPreset
}
