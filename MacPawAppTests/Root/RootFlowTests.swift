import Testing
@testable import MacPawApp

struct RootFlowTests {
    @Test
    func selectingInstalledModelMakesItsNameTheActiveChatTitle() {
        let model = makeInstalledModel(name: "Phi-4-mini", path: "/Models/Phi-4-mini")
        let state = RootViewState(models: [model], selectedModelID: model.id, chattingModelID: model.id)

        #expect(state.activeChatTitle == "Phi-4-mini")
    }
}
