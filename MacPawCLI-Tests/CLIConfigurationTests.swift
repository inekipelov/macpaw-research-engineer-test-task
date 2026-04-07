import Foundation
import Testing

@Suite("CLIConfiguration")
struct CLIConfigurationTests {
    @Test("Parses valid arguments into configuration")
    func parsesValidArguments() throws {
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

        #expect(configuration.modelPath.path == "/tmp/model")
        #expect(configuration.contextWindowOverride == 8192)
        #expect(configuration.formattedDescription.contains("maxTokens: 512"))
        #expect(configuration.formattedDescription.contains("temperature: 0.4"))
        #expect(configuration.formattedDescription.contains("topP: 0.9"))
        #expect(configuration.formattedDescription.contains("seed: 42"))
    }

    @Test("Fails when model path is missing")
    func failsWhenModelPathMissing() {
        let fileSystem = FakeFileSystem(existingDirectories: [])

        do {
            _ = try CLIConfiguration.make(arguments: ["--max-tokens", "128"], fileSystem: fileSystem)
            Issue.record("Expected missing model path error")
        } catch let error as CLIConfigurationError {
            #expect(error == .missingRequiredOption("--model-path"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Fails when numeric value is invalid")
    func failsWhenNumericValueIsInvalid() {
        let fileSystem = FakeFileSystem(existingDirectories: ["/tmp/model"])

        do {
            _ = try CLIConfiguration.make(
                arguments: ["--model-path", "/tmp/model", "--max-tokens", "abc"],
                fileSystem: fileSystem
            )
            Issue.record("Expected invalid integer error")
        } catch let error as CLIConfigurationError {
            #expect(error == .invalidInteger(option: "--max-tokens", value: "abc"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Fails when context window is not positive")
    func failsWhenNumericValueIsNegative() {
        let fileSystem = FakeFileSystem(existingDirectories: ["/tmp/model"])

        do {
            _ = try CLIConfiguration.make(
                arguments: ["--model-path", "/tmp/model", "--context-window", "-1"],
                fileSystem: fileSystem
            )
            Issue.record("Expected non-positive value error")
        } catch let error as CLIConfigurationError {
            #expect(error == .nonPositiveValue(option: "--context-window", value: "-1"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Fails when model directory does not exist")
    func failsWhenModelDirectoryDoesNotExist() {
        let fileSystem = FakeFileSystem(existingDirectories: [])

        do {
            _ = try CLIConfiguration.make(
                arguments: ["--model-path", "/tmp/missing-model"],
                fileSystem: fileSystem
            )
            Issue.record("Expected invalid model path error")
        } catch let error as CLIConfigurationError {
            #expect(error == .invalidModelPath("/tmp/missing-model"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Formats configuration for display")
    func formatsConfigurationForDisplay() throws {
        let configuration = try CLIConfiguration.make(
            arguments: [
                "--model-path", "/tmp/model",
                "--context-window", "4096"
            ],
            fileSystem: FakeFileSystem(existingDirectories: ["/tmp/model"])
        )

        #expect(
            configuration.formattedDescription ==
            """
            modelPath: /tmp/model
            maxTokens: 256
            temperature: 0.7
            topP: 0.95
            seed: none
            contextWindow: 4096
            """
        )
    }
}
