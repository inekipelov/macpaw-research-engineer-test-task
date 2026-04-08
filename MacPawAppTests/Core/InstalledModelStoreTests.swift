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
    func returnsEmptyArrayWhenStorageFileIsMissing() throws {
        let directory = try makeTemporaryDirectory()
        let store = InstalledModelStore(fileURL: directory.appending(path: "installed-models.json"))
        #expect(try store.loadModels() == [])
    }
}
