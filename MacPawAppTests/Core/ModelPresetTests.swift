import Testing
@testable import MacPawApp

struct ModelPresetTests {
    @Test
    func defaultsToBalancedPreset() {
        #expect(ModelPreset.default == .balanced)
    }
}
