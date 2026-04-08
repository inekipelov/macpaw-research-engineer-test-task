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
        fileManager: FileManager = .default,
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) -> LocalLLMRegistry {
        LocalLLMRegistry(
            loadModels: {
                try store.loadModels().sorted { $0.lastUsedAt > $1.lastUsedAt }
            },
            installModel: { url in
                try validateModelDirectory(url, fileManager: fileManager)

                var models = try store.loadModels().filter { $0.modelPath != url.path }
                let model = InstalledModel(
                    id: UUID(),
                    displayName: url.lastPathComponent,
                    modelPath: url.path,
                    lastUsedAt: dateProvider(),
                    parameters: .defaults
                )
                models.insert(model, at: 0)
                try store.saveModels(models)
                return model
            },
            updateModel: { model in
                var models = try store.loadModels()
                models.removeAll { $0.id == model.id }
                models.insert(model, at: 0)
                models.sort { $0.lastUsedAt > $1.lastUsedAt }
                try store.saveModels(models)
                return model
            },
            removeModel: { id in
                let models = try store.loadModels().filter { $0.id != id }
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
                parameters: .defaults
            )
        },
        updateModel: { $0 },
        removeModel: { _ in }
    )

    private static func validateModelDirectory(_ url: URL, fileManager: FileManager) throws {
        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw LocalLLMRegistryError.invalidModelDirectory(url.path)
        }
    }
}
