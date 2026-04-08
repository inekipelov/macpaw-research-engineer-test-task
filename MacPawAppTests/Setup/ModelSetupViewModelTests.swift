import Testing
@testable import MacPawApp

@MainActor
struct ModelSetupViewModelTests {
    @Test
    func updatingParametersPersistsToSelectedModel() throws {
        let model = makeInstalledModel()
        let viewModel = ModelSetupViewModel(model: model)
        viewModel.maxTokensText = "512"

        let updated = try viewModel.buildUpdatedModel()

        #expect(updated.parameters.maxTokens == 512)
    }

    @Test
    func rejectsInvalidTopPValues() {
        let model = makeInstalledModel()
        let viewModel = ModelSetupViewModel(model: model)
        viewModel.topPText = "5"

        #expect(throws: ModelSetupValidationError.invalidTopP) {
            try viewModel.buildUpdatedModel()
        }
    }
}
