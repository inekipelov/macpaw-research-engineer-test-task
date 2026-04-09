import Testing
@testable import MacPawApp

@MainActor
struct ModelSetupViewModelTests {
    @Test
    func updatingPresetPersistsToSelectedModel() throws {
        let model = makeInstalledModel()
        let viewModel = ModelSetupViewModel(model: model)
        viewModel.selectedPreset = .precise

        let updated = viewModel.buildUpdatedModel()

        #expect(updated.generationPreset == .precise)
    }

    @Test
    func initializesSelectedPresetFromModel() {
        let model = makeInstalledModel()
        let viewModel = ModelSetupViewModel(model: model)

        #expect(viewModel.selectedPreset == .balanced)
    }
}
