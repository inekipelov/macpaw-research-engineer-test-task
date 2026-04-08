import Foundation

struct AppPaths {
    let applicationSupportDirectory: URL

    var installedModelsFileURL: URL {
        applicationSupportDirectory.appending(path: "installed-models.json")
    }

    static let live = AppPaths(
        applicationSupportDirectory: FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "MacPawApp", directoryHint: .isDirectory)
    )
}
