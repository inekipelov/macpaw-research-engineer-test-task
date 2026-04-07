import Testing

@Suite("ModelHistoryStore")
struct ModelHistoryStoreTests {
    @Test("Records most recent model first without duplicates")
    func recordsMostRecentModelFirstWithoutDuplicates() {
        let store = ModelHistoryStore(
            keyValueStore: InMemoryKeyValueStore(),
            historyLimit: 5
        )

        store.recordModelPath("/models/one")
        store.recordModelPath("/models/two")
        store.recordModelPath("/models/one")

        #expect(store.modelPaths() == ["/models/one", "/models/two"])
    }

    @Test("Removes a model path from history")
    func removesMissingModelFromHistory() {
        let store = ModelHistoryStore(
            keyValueStore: InMemoryKeyValueStore(seed: [ModelHistoryStore.historyKey: ["/models/one", "/models/two"]]),
            historyLimit: 5
        )

        store.removeModelPath("/models/one")

        #expect(store.modelPaths() == ["/models/two"])
    }

    @Test("Trims history to configured limit")
    func trimsHistoryToConfiguredLimit() {
        let store = ModelHistoryStore(
            keyValueStore: InMemoryKeyValueStore(),
            historyLimit: 2
        )

        store.recordModelPath("/models/one")
        store.recordModelPath("/models/two")
        store.recordModelPath("/models/three")

        #expect(store.modelPaths() == ["/models/three", "/models/two"])
    }
}
