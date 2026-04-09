import Foundation
import Testing
@testable import MacPawApp

@MainActor
struct LocalLLMRegistryTests {
    @Test
    func installingModelUsesBalancedPresetByDefault() async throws {
        let directory = try makeTemporaryDirectory()
        let modelDirectory = directory.appending(path: "Phi-4-mini", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)

        let store = InstalledModelStore(fileURL: directory.appending(path: "installed-models.json"))
        let registry = LocalLLMRegistry.live(store: store, dateProvider: { .distantPast })

        let installed = try await registry.installModel(at: modelDirectory)

        #expect(installed.generationPreset == .balanced)
    }

    @Test
    func installingModelReplacesUnreadableStoreContents() async throws {
        let directory = try makeTemporaryDirectory()
        let modelDirectory = directory.appending(path: "Phi-4-mini", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)

        let fileURL = directory.appending(path: "installed-models.json")
        let legacyPayload = """
        [
          {
            "displayName" : "Old Model",
            "id" : "00000000-0000-0000-0000-000000000001",
            "lastUsedAt" : "2026-04-09T08:00:00Z",
            "modelPath" : "/Models/Old",
            "parameters" : {
              "contextWindow" : 4096,
              "maxTokens" : 256,
              "seed" : null,
              "temperature" : 0.7,
              "topP" : 0.95
            }
          }
        ]
        """
        try legacyPayload.data(using: .utf8)?.write(to: fileURL)

        let store = InstalledModelStore(fileURL: fileURL)
        let registry = LocalLLMRegistry.live(store: store, dateProvider: { .distantPast })

        let installed = try await registry.installModel(at: modelDirectory)
        let loaded = try store.loadModels()

        #expect(installed.displayName == "Phi-4-mini")
        #expect(loaded.count == 1)
        #expect(loaded.first?.displayName == "Phi-4-mini")
    }
}
