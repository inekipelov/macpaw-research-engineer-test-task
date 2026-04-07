import Foundation

enum ModelSelectionMenuAction: Equatable {
    case selectHistoryPath(String)
    case enterNewPath
    case exit
}

struct ModelSelectionMenu {
    static func text(for history: [String]) -> String {
        var lines = ["Model Selection"]

        if history.isEmpty {
            lines.append("No recent models found.")
        } else {
            lines.append("Recent models:")
            for (index, path) in history.enumerated() {
                lines.append("\(index + 1). \(path)")
            }
        }

        lines.append("n. Enter new model path")
        lines.append("0. Exit")
        return lines.joined(separator: "\n")
    }

    static func parse(_ input: String, history: [String]) -> ModelSelectionMenuAction? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lowercased = trimmed.lowercased()
        switch lowercased {
        case "0", "exit", "quit", "/exit":
            return .exit
        case "n", "new", "add":
            return .enterNewPath
        default:
            guard let index = Int(trimmed), history.indices.contains(index - 1) else {
                return nil
            }
            return .selectHistoryPath(history[index - 1])
        }
    }
}
