import Foundation

enum ModelSetupValidationError: LocalizedError, Equatable {
    case invalidMaxTokens
    case invalidTemperature
    case invalidTopP
    case invalidSeed
    case invalidContextWindow

    var errorDescription: String? {
        switch self {
        case .invalidMaxTokens:
            return "Max tokens must be a positive integer."
        case .invalidTemperature:
            return "Temperature must be a number greater than or equal to 0."
        case .invalidTopP:
            return "Top-p must be a number greater than 0 and less than or equal to 1."
        case .invalidSeed:
            return "Seed must be a non-negative integer."
        case .invalidContextWindow:
            return "Context window must be a positive integer."
        }
    }
}

@MainActor
final class ModelSetupViewModel: ObservableObject {
    let model: InstalledModel

    @Published var maxTokensText: String
    @Published var temperatureText: String
    @Published var topPText: String
    @Published var seedText: String
    @Published var contextWindowText: String

    init(model: InstalledModel) {
        self.model = model
        self.maxTokensText = String(model.parameters.maxTokens)
        self.temperatureText = String(model.parameters.temperature)
        self.topPText = String(model.parameters.topP)
        self.seedText = model.parameters.seed.map(String.init) ?? ""
        self.contextWindowText = model.parameters.contextWindow.map(String.init) ?? ""
    }

    var validationMessage: String? {
        do {
            _ = try buildUpdatedModel()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func buildUpdatedModel() throws -> InstalledModel {
        let maxTokens = try parsePositiveInt(maxTokensText, error: .invalidMaxTokens)
        let temperature = try parseNonNegativeDouble(temperatureText, error: .invalidTemperature)
        let topP = try parseTopP(topPText)
        let seed = try parseOptionalNonNegativeInt(seedText, error: .invalidSeed)
        let contextWindow = try parseOptionalPositiveInt(contextWindowText, error: .invalidContextWindow)

        var updated = model
        updated.parameters = ModelParameters(
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            seed: seed,
            contextWindow: contextWindow
        )
        return updated
    }

    private func parsePositiveInt(_ value: String, error: ModelSetupValidationError) throws -> Int {
        guard let parsed = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)), parsed > 0 else {
            throw error
        }
        return parsed
    }

    private func parseOptionalPositiveInt(_ value: String, error: ModelSetupValidationError) throws -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        return try parsePositiveInt(trimmed, error: error)
    }

    private func parseNonNegativeDouble(_ value: String, error: ModelSetupValidationError) throws -> Double {
        guard let parsed = Double(value.trimmingCharacters(in: .whitespacesAndNewlines)), parsed >= 0 else {
            throw error
        }
        return parsed
    }

    private func parseTopP(_ value: String) throws -> Double {
        guard let parsed = Double(value.trimmingCharacters(in: .whitespacesAndNewlines)), parsed > 0, parsed <= 1 else {
            throw ModelSetupValidationError.invalidTopP
        }
        return parsed
    }

    private func parseOptionalNonNegativeInt(_ value: String, error: ModelSetupValidationError) throws -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        guard let parsed = Int(trimmed), parsed >= 0 else {
            throw error
        }

        return parsed
    }
}
