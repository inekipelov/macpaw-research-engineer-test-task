import Foundation
import Testing
@testable import MacPawApp

struct InstalledModelStoreTests {
    @Test
    func savesAndLoadsInstalledModels() throws {
        let directory = try makeTemporaryDirectory()
        let store = InstalledModelStore(fileURL: directory.appending(path: "installed-models.json"))

        let model = makeInstalledModel(lastUsedAt: .distantPast)

        try store.saveModels([model])
        let loaded = try store.loadModels()

        #expect(loaded == [model])
    }

    @Test
    func persistsPresetOnlySchema() throws {
        let directory = try makeTemporaryDirectory()
        let fileURL = directory.appending(path: "installed-models.json")
        let store = InstalledModelStore(fileURL: fileURL)
        let model = makeInstalledModel()

        try store.saveModels([model])

        let data = try Data(contentsOf: fileURL)
        let payload = try #require(String(data: data, encoding: .utf8))
        #expect(payload.contains("\"generationPreset\""))
        #expect(payload.contains("\"balanced\""))
        #expect(payload.contains("\"parameters\"") == false)
    }

    @Test
    func returnsEmptyArrayWhenStorageFileIsMissing() throws {
        let directory = try makeTemporaryDirectory()
        let store = InstalledModelStore(fileURL: directory.appending(path: "installed-models.json"))
        #expect(try store.loadModels() == [])
    }
}
