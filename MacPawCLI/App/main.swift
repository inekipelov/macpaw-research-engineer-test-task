import Foundation

let terminal = StandardIO()

do {
    let launchOptions = try LaunchOptions.make(arguments: Array(CommandLine.arguments.dropFirst()))
    let coordinator = AppCoordinator(
        launchOptions: launchOptions,
        historyStore: ModelHistoryStore(),
        chatServiceFactory: LocalChatServiceFactory(),
        terminal: terminal
    )
    let exitCode = await coordinator.run()
    Foundation.exit(exitCode)
} catch let error as CLIConfigurationError {
    terminal.writeErrorLine(error.message)
    terminal.writeErrorLine("")
    terminal.writeErrorLine(LaunchOptions.usageText)
    Foundation.exit(1)
} catch {
    terminal.writeErrorLine("Unexpected startup error: \(error.localizedDescription)")
    Foundation.exit(1)
}
