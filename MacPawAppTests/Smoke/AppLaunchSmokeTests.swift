import Testing
@testable import MacPawApp

struct AppLaunchSmokeTests {
    @Test
    func previewEnvironmentCanBeConstructed() throws {
        let environment = AppEnvironment.preview
        #expect(try environment.registry.loadModels() == [])
    }
}
