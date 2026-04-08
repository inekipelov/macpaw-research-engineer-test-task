import Foundation
import Testing
@testable import MacPawApp

@MainActor
struct LibraryViewModelTests {
    @Test
    func installAddsModelToFrontOfHistory() async throws {
        let directory = try makeTemporaryDirectory()
        let modelDirectory = directory.appending(path: "Llama-3.2-1B", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)

        let store = InstalledModelStore(fileURL: directory.appending(path: "installed-models.json"))
        let registry = LocalLLMRegistry.live(store: store, dateProvider: { .distantPast })
        let viewModel = LibraryViewModel(registry: registry)

        try await viewModel.installModel(at: modelDirectory)

        let models = viewModel.models
        #expect(models.first?.displayName == "Llama-3.2-1B")
    }
}
