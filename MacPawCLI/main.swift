import Foundation

let terminal = StandardIO()

do {
    let configuration = try CLIConfiguration.make(arguments: Array(CommandLine.arguments.dropFirst()))
    let service = LocalMLXChatService(configuration: configuration)
    let session = ChatSession(configuration: configuration, service: service, terminal: terminal)
    let exitCode = await session.run()
    Foundation.exit(exitCode)
} catch let error as CLIConfigurationError {
    terminal.writeErrorLine(error.message)
    terminal.writeErrorLine("")
    terminal.writeErrorLine(CLIConfiguration.usageText)
    Foundation.exit(1)
} catch {
    terminal.writeErrorLine("Unexpected startup error: \(error.localizedDescription)")
    Foundation.exit(1)
}
