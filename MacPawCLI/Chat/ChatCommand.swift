import Foundation

enum ChatCommand: Equatable {
    case prompt(String)
    case help
    case config
    case close
    case exit

    static func parse(line: String) -> ChatCommand? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        switch trimmed.lowercased() {
        case "/help":
            return .help
        case "/config":
            return .config
        case "close", "/close":
            return .close
        case "/exit", "exit", "quit":
            return .exit
        default:
            return .prompt(trimmed)
        }
    }
}
