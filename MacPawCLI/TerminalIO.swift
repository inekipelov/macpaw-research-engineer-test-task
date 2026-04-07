import Foundation

protocol TerminalIO: AnyObject {
    func readInput(prompt: String) -> String?
    func write(_ text: String)
    func writeLine(_ text: String)
    func writeErrorLine(_ text: String)
}

final class StandardIO: TerminalIO {
    func readInput(prompt: String) -> String? {
        write(prompt)
        fflush(stdout)
        return readLine()
    }

    func write(_ text: String) {
        print(text, terminator: "")
    }

    func writeLine(_ text: String) {
        print(text)
    }

    func writeErrorLine(_ text: String) {
        guard let data = (text + "\n").data(using: .utf8) else { return }
        FileHandle.standardError.write(data)
    }
}
