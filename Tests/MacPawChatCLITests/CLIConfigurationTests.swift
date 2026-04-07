import XCTest
@testable import MacPawChatCLI

final class CLIConfigurationTests: XCTestCase {
    func testParsesValidArguments() throws {
        let fileSystem = FakeFileSystem(existingDirectories: ["/tmp/model"])

        let configuration = try CLIConfiguration.make(
            arguments: [
                "--model-path", "/tmp/model",
                "--max-tokens", "512",
                "--temperature", "0.4",
                "--top-p", "0.9",
                "--seed", "42",
                "--context-window", "8192"
            ],
            fileSystem: fileSystem
        )

        XCTAssertEqual(configuration.modelPath.path, "/tmp/model")
        XCTAssertEqual(configuration.generationOptions.maxTokens, 512)
        XCTAssertEqual(configuration.generationOptions.temperature, 0.4)
        XCTAssertEqual(configuration.generationOptions.topP, 0.9)
        XCTAssertEqual(configuration.generationOptions.seed, 42)
        XCTAssertEqual(configuration.contextWindowOverride, 8192)
    }

    func testFailsWhenModelPathMissing() {
        let fileSystem = FakeFileSystem(existingDirectories: [])

        XCTAssertThrowsError(
            try CLIConfiguration.make(arguments: ["--max-tokens", "128"], fileSystem: fileSystem)
        ) { error in
            XCTAssertEqual(error as? CLIConfigurationError, .missingRequiredOption("--model-path"))
        }
    }

    func testFailsWhenNumericValueIsInvalid() {
        let fileSystem = FakeFileSystem(existingDirectories: ["/tmp/model"])

        XCTAssertThrowsError(
            try CLIConfiguration.make(
                arguments: ["--model-path", "/tmp/model", "--max-tokens", "abc"],
                fileSystem: fileSystem
            )
        ) { error in
            XCTAssertEqual(
                error as? CLIConfigurationError,
                .invalidInteger(option: "--max-tokens", value: "abc")
            )
        }
    }

    func testFailsWhenNumericValueIsNegative() {
        let fileSystem = FakeFileSystem(existingDirectories: ["/tmp/model"])

        XCTAssertThrowsError(
            try CLIConfiguration.make(
                arguments: ["--model-path", "/tmp/model", "--context-window", "-1"],
                fileSystem: fileSystem
            )
        ) { error in
            XCTAssertEqual(
                error as? CLIConfigurationError,
                .nonPositiveValue(option: "--context-window", value: "-1")
            )
        }
    }

    func testFailsWhenModelDirectoryDoesNotExist() {
        let fileSystem = FakeFileSystem(existingDirectories: [])

        XCTAssertThrowsError(
            try CLIConfiguration.make(
                arguments: ["--model-path", "/tmp/missing-model"],
                fileSystem: fileSystem
            )
        ) { error in
            XCTAssertEqual(
                error as? CLIConfigurationError,
                .invalidModelPath("/tmp/missing-model")
            )
        }
    }
}
