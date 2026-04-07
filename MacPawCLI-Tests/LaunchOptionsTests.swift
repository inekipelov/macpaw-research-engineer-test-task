import Foundation
import Testing

@Suite("LaunchOptions")
struct LaunchOptionsTests {
    @Test("Allows launching without model path")
    func allowsLaunchingWithoutModelPath() throws {
        let options = try LaunchOptions.make(arguments: [])

        #expect(options.initialModelPath == nil)
        #expect(options.contextWindowOverride == nil)
    }

    @Test("Parses generation options and builds CLI configuration")
    func parsesGenerationOptionsAndBuildsConfiguration() throws {
        let fileSystem = FakeFileSystem(existingDirectories: ["/tmp/model"])
        let options = try LaunchOptions.make(
            arguments: [
                "--model-path", "/tmp/model",
                "--max-tokens", "128",
                "--temperature", "0.2",
                "--top-p", "0.8",
                "--seed", "7",
                "--context-window", "2048"
            ],
            fileSystem: fileSystem
        )

        #expect(options.initialModelPath?.path == "/tmp/model")
        #expect(options.contextWindowOverride == 2048)

        let configuration = options.configuration(for: URL(filePath: "/tmp/other-model"))
        #expect(configuration.modelPath.path == "/tmp/other-model")
        #expect(configuration.contextWindowOverride == 2048)
        #expect(configuration.formattedDescription.contains("maxTokens: 128"))
        #expect(configuration.formattedDescription.contains("temperature: 0.2"))
        #expect(configuration.formattedDescription.contains("topP: 0.8"))
        #expect(configuration.formattedDescription.contains("seed: 7"))
    }

    @Test("Fails for unknown option")
    func failsForUnknownOption() {
        do {
            _ = try LaunchOptions.make(arguments: ["--bogus"])
            Issue.record("Expected unknown option error")
        } catch let error as CLIConfigurationError {
            #expect(error == .unknownOption("--bogus"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Fails when double value is invalid")
    func failsWhenDoubleValueIsInvalid() {
        do {
            _ = try LaunchOptions.make(arguments: ["--temperature", "warm"])
            Issue.record("Expected invalid double error")
        } catch let error as CLIConfigurationError {
            #expect(error == .invalidDouble(option: "--temperature", value: "warm"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Fails when option value is missing")
    func failsWhenOptionValueIsMissing() {
        do {
            _ = try LaunchOptions.make(arguments: ["--model-path"])
            Issue.record("Expected missing value error")
        } catch let error as CLIConfigurationError {
            #expect(error == .missingValue("--model-path"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
