import Foundation

struct InstalledModelStore {
    let fileURL: URL

    static func live(paths: AppPaths) -> InstalledModelStore {
        InstalledModelStore(fileURL: paths.installedModelsFileURL)
    }

    func loadModels() throws -> [InstalledModel] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([InstalledModel].self, from: data)
    }

    func saveModels(_ models: [InstalledModel]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(models)
        try data.write(to: fileURL, options: .atomic)
    }
}
