import Foundation
import LocalMLXChatCore

struct LaunchOptions: Equatable {
    let initialModelPath: URL?
    let generationOptions: GenerationOptions
    let contextWindowOverride: Int?

    static var usageText: String {
        CLIConfiguration.usageText
    }

    static func make(
        arguments: [String],
        fileSystem: FileSystem = LocalFileSystem()
    ) throws -> LaunchOptions {
        var modelPath: URL?
        var maxTokens = 256
        var temperature = 0.7
        var topP = 0.95
        var seed: UInt64?
        var contextWindowOverride: Int?

        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--model-path":
                let value = try value(after: argument, in: arguments, index: &index)
                modelPath = URL(filePath: value)
            case "--max-tokens":
                let value = try value(after: argument, in: arguments, index: &index)
                maxTokens = try parsePositiveInteger(value, option: argument)
            case "--temperature":
                let value = try value(after: argument, in: arguments, index: &index)
                temperature = try parseNonNegativeDouble(value, option: argument)
            case "--top-p":
                let value = try value(after: argument, in: arguments, index: &index)
                topP = try parsePositiveDouble(value, option: argument)
            case "--seed":
                let value = try value(after: argument, in: arguments, index: &index)
                seed = try parseSeed(value, option: argument)
            case "--context-window":
                let value = try value(after: argument, in: arguments, index: &index)
                contextWindowOverride = try parsePositiveInteger(value, option: argument)
            default:
                throw CLIConfigurationError.unknownOption(argument)
            }

            index += 1
        }

        if let modelPath, !fileSystem.directoryExists(at: modelPath) {
            throw CLIConfigurationError.invalidModelPath(modelPath.path)
        }

        return LaunchOptions(
            initialModelPath: modelPath,
            generationOptions: GenerationOptions(
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                seed: seed
            ),
            contextWindowOverride: contextWindowOverride
        )
    }

    func configuration(for modelPath: URL) -> CLIConfiguration {
        CLIConfiguration(
            modelPath: modelPath,
            generationOptions: generationOptions,
            contextWindowOverride: contextWindowOverride
        )
    }

    private static func value(
        after option: String,
        in arguments: [String],
        index: inout Int
    ) throws -> String {
        let nextIndex = index + 1
        guard nextIndex < arguments.count else {
            throw CLIConfigurationError.missingValue(option)
        }

        index = nextIndex
        return arguments[nextIndex]
    }

    private static func parsePositiveInteger(_ value: String, option: String) throws -> Int {
        guard let integer = Int(value) else {
            throw CLIConfigurationError.invalidInteger(option: option, value: value)
        }
        guard integer > 0 else {
            throw CLIConfigurationError.nonPositiveValue(option: option, value: value)
        }
        return integer
    }

    private static func parseSeed(_ value: String, option: String) throws -> UInt64 {
        guard let integer = Int64(value) else {
            throw CLIConfigurationError.invalidInteger(option: option, value: value)
        }
        guard integer >= 0 else {
            throw CLIConfigurationError.nonPositiveValue(option: option, value: value)
        }
        return UInt64(integer)
    }

    private static func parseNonNegativeDouble(_ value: String, option: String) throws -> Double {
        guard let double = Double(value) else {
            throw CLIConfigurationError.invalidDouble(option: option, value: value)
        }
        guard double >= 0 else {
            throw CLIConfigurationError.negativeValue(option: option, value: value)
        }
        return double
    }

    private static func parsePositiveDouble(_ value: String, option: String) throws -> Double {
        guard let double = Double(value) else {
            throw CLIConfigurationError.invalidDouble(option: option, value: value)
        }
        guard double > 0 else {
            throw CLIConfigurationError.nonPositiveValue(option: option, value: value)
        }
        return double
    }
}
