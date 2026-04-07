import XCTest
@testable import MacPawChatCLI

final class ChatCommandTests: XCTestCase {
    func testRecognizesSlashCommands() {
        XCTAssertEqual(ChatCommand.parse(line: "/help"), .help)
        XCTAssertEqual(ChatCommand.parse(line: "/config"), .config)
        XCTAssertEqual(ChatCommand.parse(line: "/exit"), .exit)
    }

    func testTreatsRegularInputAsPrompt() {
        XCTAssertEqual(ChatCommand.parse(line: "Hello there"), .prompt("Hello there"))
    }

    func testRecognizesExitAliases() {
        XCTAssertEqual(ChatCommand.parse(line: "exit"), .exit)
        XCTAssertEqual(ChatCommand.parse(line: "quit"), .exit)
    }

    func testReturnsNilForBlankInput() {
        XCTAssertNil(ChatCommand.parse(line: ""))
        XCTAssertNil(ChatCommand.parse(line: "   "))
    }
}
