import Foundation

@MainActor
final class ModelSetupViewModel: ObservableObject {
    let model: InstalledModel

    @Published var selectedPreset: ModelPreset

    init(model: InstalledModel) {
        self.model = model
        self.selectedPreset = model.generationPreset
    }

    var presetSummary: String {
        selectedPreset.summary
    }

    func buildUpdatedModel() -> InstalledModel {
        var updated = model
        updated.generationPreset = selectedPreset
        return updated
    }
}
