import Foundation
@testable import MacPawApp

func makeTemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

func makeInstalledModel(
    name: String = "Llama-3.2-1B",
    path: String = "/Models/Llama-3.2-1B",
    lastUsedAt: Date = .now,
    parameters: ModelParameters = .defaults
) -> InstalledModel {
    InstalledModel(
        id: UUID(),
        displayName: name,
        modelPath: path,
        lastUsedAt: lastUsedAt,
        parameters: parameters
    )
}
