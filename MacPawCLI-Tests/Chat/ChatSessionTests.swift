import Testing

@Suite("ChatSession")
struct ChatSessionTests {
    @Test("Close command returns close result")
    func closeCommandReturnsCloseResult() async {
        let terminal = FakeTerminal(inputs: ["close"])
        let session = ChatSession(
            configuration: makeConfiguration(),
            service: FakeChatService(),
            terminal: terminal
        )

        let result = await session.run()

        #expect(result == .close)
    }

    @Test("Exit command returns exit result")
    func exitCommandReturnsExitResult() async {
        let terminal = FakeTerminal(inputs: ["/exit"])
        let session = ChatSession(
            configuration: makeConfiguration(),
            service: FakeChatService(),
            terminal: terminal
        )

        let result = await session.run()

        #expect(result == .exit)
    }

    @Test("Config command prints active configuration")
    func configCommandPrintsActiveConfiguration() async {
        let terminal = FakeTerminal(inputs: ["/config", "/exit"])
        let session = ChatSession(
            configuration: makeConfiguration(modelPath: "/models/current"),
            service: FakeChatService(),
            terminal: terminal
        )

        _ = await session.run()

        #expect(terminal.stdout.contains("modelPath: /models/current"))
        #expect(terminal.stdout.contains("maxTokens: 256"))
        #expect(terminal.stdout.contains("temperature: 0.7"))
        #expect(terminal.stdout.contains("topP: 0.95"))
    }
}
