import SwiftUI

@main
struct MacPawApp: App {
    private let environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup("MacPaw Chat") {
            RootView(environment: environment)
        }
        .defaultSize(width: 1180, height: 760)
    }
}
