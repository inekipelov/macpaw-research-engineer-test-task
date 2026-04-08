import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var models: [InstalledModel]
    @Published var selectedModelID: UUID?
    @Published var errorMessage: String?
    @Published private(set) var loadState: LoadableState = .idle

    private let registry: LocalLLMRegistry

    init(registry: LocalLLMRegistry) {
        self.registry = registry

        do {
            let loadedModels = try registry.loadModels()
            self.models = loadedModels
            self.selectedModelID = loadedModels.first?.id
            self.loadState = .loaded
        } catch {
            self.models = []
            self.selectedModelID = nil
            self.errorMessage = error.localizedDescription
            self.loadState = .failed(error.localizedDescription)
        }
    }

    var selectedModel: InstalledModel? {
        guard let selectedModelID else {
            return nil
        }

        return models.first(where: { $0.id == selectedModelID })
    }

    func selectModel(id: UUID?) {
        selectedModelID = id
    }

    @discardableResult
    func installModel(at url: URL) async throws -> InstalledModel {
        loadState = .loading
        defer { loadState = .loaded }

        do {
            let model = try await registry.installModel(at: url)
            try reload()
            selectedModelID = model.id
            return model
        } catch {
            errorMessage = error.localizedDescription
            loadState = .failed(error.localizedDescription)
            throw error
        }
    }

    @discardableResult
    func updateModel(_ model: InstalledModel) async throws -> InstalledModel {
        loadState = .loading
        defer { loadState = .loaded }

        do {
            let updated = try await registry.updateModel(model)
            try reload()
            selectedModelID = updated.id
            return updated
        } catch {
            errorMessage = error.localizedDescription
            loadState = .failed(error.localizedDescription)
            throw error
        }
    }

    func removeSelectedModel() async throws {
        guard let selectedModelID else {
            return
        }

        loadState = .loading
        defer { loadState = .loaded }

        do {
            try await registry.removeModel(id: selectedModelID)
            try reload()
        } catch {
            errorMessage = error.localizedDescription
            loadState = .failed(error.localizedDescription)
            throw error
        }
    }

    private func reload() throws {
        let loadedModels = try registry.loadModels()
        models = loadedModels
        if let selectedModelID, loadedModels.contains(where: { $0.id == selectedModelID }) {
            self.selectedModelID = selectedModelID
        } else {
            self.selectedModelID = loadedModels.first?.id
        }
        errorMessage = nil
    }
}
