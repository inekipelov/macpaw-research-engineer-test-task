import Foundation

enum LocalLLMRegistryError: LocalizedError, Equatable {
    case invalidModelDirectory(String)

    var errorDescription: String? {
        switch self {
        case .invalidModelDirectory(let path):
            return "Model folder is missing or invalid: \(path)"
        }
    }
}

struct LocalLLMRegistry {
    private let loadModelsOperation: @Sendable () throws -> [InstalledModel]
    private let installModelOperation: @Sendable (URL) async throws -> InstalledModel
    private let updateModelOperation: @Sendable (InstalledModel) async throws -> InstalledModel
    private let removeModelOperation: @Sendable (UUID) async throws -> Void

    init(
        loadModels: @escaping @Sendable () throws -> [InstalledModel],
        installModel: @escaping @Sendable (URL) async throws -> InstalledModel,
        updateModel: @escaping @Sendable (InstalledModel) async throws -> InstalledModel,
        removeModel: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.loadModelsOperation = loadModels
        self.installModelOperation = installModel
        self.updateModelOperation = updateModel
        self.removeModelOperation = removeModel
    }

    func loadModels() throws -> [InstalledModel] {
        try loadModelsOperation()
    }

    func installModel(at url: URL) async throws -> InstalledModel {
        try await installModelOperation(url)
    }

    func updateModel(_ model: InstalledModel) async throws -> InstalledModel {
        try await updateModelOperation(model)
    }

    func removeModel(id: UUID) async throws {
        try await removeModelOperation(id)
    }

    static func live(
        store: InstalledModelStore,
        dateProvider: @escaping @Sendable () -> Date = { .now }
    ) -> LocalLLMRegistry {
        LocalLLMRegistry(
            loadModels: {
                try store.loadModels().sorted { $0.lastUsedAt > $1.lastUsedAt }
            },
            installModel: { url in
                try validateModelDirectory(url)

                var models = try loadModelsForMutation(from: store).filter { $0.modelPath != url.path }
                let model = InstalledModel(
                    id: UUID(),
                    displayName: url.lastPathComponent,
                    modelPath: url.path,
                    lastUsedAt: dateProvider(),
                    generationPreset: .default
                )
                models.insert(model, at: 0)
                try store.saveModels(models)
                return model
            },
            updateModel: { model in
                var models = try loadModelsForMutation(from: store)
                models.removeAll { $0.id == model.id }
                models.insert(model, at: 0)
                models.sort { $0.lastUsedAt > $1.lastUsedAt }
                try store.saveModels(models)
                return model
            },
            removeModel: { id in
                let models = try loadModelsForMutation(from: store).filter { $0.id != id }
                try store.saveModels(models)
            }
        )
    }

    static let preview = LocalLLMRegistry(
        loadModels: { [] },
        installModel: { url in
            InstalledModel(
                id: UUID(),
                displayName: url.lastPathComponent,
                modelPath: url.path,
                lastUsedAt: .now,
                generationPreset: .default
            )
        },
        updateModel: { $0 },
        removeModel: { _ in }
    )

    private static func validateModelDirectory(_ url: URL) throws {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
        guard values?.isDirectory == true else {
            throw LocalLLMRegistryError.invalidModelDirectory(url.path)
        }
    }

    private static func loadModelsForMutation(from store: InstalledModelStore) throws -> [InstalledModel] {
        do {
            return try store.loadModels()
        } catch is DecodingError {
            return []
        }
    }
}
