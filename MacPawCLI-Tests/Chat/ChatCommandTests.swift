import Testing

@Suite("ChatCommand")
struct ChatCommandTests {
    @Test("Recognizes slash commands")
    func recognizesSlashCommands() {
        #expect(ChatCommand.parse(line: "/help") == .help)
        #expect(ChatCommand.parse(line: "/config") == .config)
        #expect(ChatCommand.parse(line: "/exit") == .exit)
    }

    @Test("Treats regular input as prompt")
    func treatsRegularInputAsPrompt() {
        #expect(ChatCommand.parse(line: "Hello there") == .prompt("Hello there"))
    }

    @Test("Recognizes exit aliases")
    func recognizesExitAliases() {
        #expect(ChatCommand.parse(line: "exit") == .exit)
        #expect(ChatCommand.parse(line: "quit") == .exit)
    }

    @Test("Recognizes close aliases")
    func recognizesCloseAliases() {
        #expect(ChatCommand.parse(line: "close") == .close)
        #expect(ChatCommand.parse(line: "/close") == .close)
    }

    @Test("Returns nil for blank input")
    func returnsNilForBlankInput() {
        #expect(ChatCommand.parse(line: "") == nil)
        #expect(ChatCommand.parse(line: "   ") == nil)
    }
}
