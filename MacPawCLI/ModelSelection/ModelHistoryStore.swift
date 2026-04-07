import Foundation

protocol KeyValueStore: AnyObject {
    func stringArray(forKey defaultName: String) -> [String]?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: KeyValueStore {}

final class ModelHistoryStore {
    static let historyKey = "recentModelPaths"

    private let keyValueStore: KeyValueStore
    private let historyLimit: Int

    init(
        keyValueStore: KeyValueStore = UserDefaults.standard,
        historyLimit: Int = 5
    ) {
        self.keyValueStore = keyValueStore
        self.historyLimit = historyLimit
    }

    func modelPaths() -> [String] {
        keyValueStore.stringArray(forKey: Self.historyKey) ?? []
    }

    func recordModelPath(_ path: String) {
        var paths = modelPaths().filter { $0 != path }
        paths.insert(path, at: 0)
        if paths.count > historyLimit {
            paths = Array(paths.prefix(historyLimit))
        }
        keyValueStore.set(paths, forKey: Self.historyKey)
    }

    func removeModelPath(_ path: String) {
        let updated = modelPaths().filter { $0 != path }
        keyValueStore.set(updated, forKey: Self.historyKey)
    }
}
