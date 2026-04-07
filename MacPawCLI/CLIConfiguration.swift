import Foundation
import LocalMLXChatCore

struct CLIConfiguration: Equatable {
    let modelPath: URL
    let generationOptions: GenerationOptions
    let contextWindowOverride: Int?

    static func make(
        arguments: [String],
        fileSystem: FileSystem = LocalFileSystem()
    ) throws -> CLIConfiguration {
        var modelPath: String?
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
                modelPath = try value(after: argument, in: arguments, index: &index)
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

        guard let modelPath else {
            throw CLIConfigurationError.missingRequiredOption("--model-path")
        }

        let modelURL = URL(filePath: modelPath)
        guard fileSystem.directoryExists(at: modelURL) else {
            throw CLIConfigurationError.invalidModelPath(modelURL.path)
        }

        return CLIConfiguration(
            modelPath: modelURL,
            generationOptions: GenerationOptions(
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                seed: seed
            ),
            contextWindowOverride: contextWindowOverride
        )
    }

    var localModelConfiguration: LocalModelConfiguration {
        LocalModelConfiguration(
            modelPath: modelPath,
            contextWindowOverride: contextWindowOverride,
            defaultGenerationOptions: generationOptions
        )
    }

    var formattedDescription: String {
        [
            "modelPath: \(modelPath.path)",
            "maxTokens: \(generationOptions.maxTokens ?? 256)",
            "temperature: \(generationOptions.temperature ?? 0.7)",
            "topP: \(generationOptions.topP ?? 1.0)",
            "seed: \(generationOptions.seed.map(String.init) ?? "none")",
            "contextWindow: \(contextWindowOverride.map(String.init) ?? "none")"
        ].joined(separator: "\n")
    }

    static var usageText: String {
        """
        Usage: MacPawCLI --model-path <path> [options]

        Options:
          --model-path <path>       Local MLX model directory (required)
          --max-tokens <int>        Maximum output tokens (default: 256)
          --temperature <double>    Sampling temperature (default: 0.7)
          --top-p <double>          Nucleus sampling value (default: 0.95)
          --seed <int>              Optional deterministic seed
          --context-window <int>    Optional context window override

        REPL commands:
          /help                     Show help
          /config                   Show effective configuration
          /exit                     Exit the session
        """
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

enum CLIConfigurationError: Error, Equatable {
    case missingRequiredOption(String)
    case missingValue(String)
    case invalidInteger(option: String, value: String)
    case invalidDouble(option: String, value: String)
    case negativeValue(option: String, value: String)
    case nonPositiveValue(option: String, value: String)
    case invalidModelPath(String)
    case unknownOption(String)

    var message: String {
        switch self {
        case .missingRequiredOption(let option):
            return "Missing required option: \(option)"
        case .missingValue(let option):
            return "Missing value for option: \(option)"
        case .invalidInteger(let option, let value):
            return "Invalid integer for \(option): \(value)"
        case .invalidDouble(let option, let value):
            return "Invalid number for \(option): \(value)"
        case .negativeValue(let option, let value):
            return "Value for \(option) cannot be negative: \(value)"
        case .nonPositiveValue(let option, let value):
            return "Value for \(option) must be greater than zero: \(value)"
        case .invalidModelPath(let path):
            return "Model path is invalid or not a directory: \(path)"
        case .unknownOption(let option):
            return "Unknown option: \(option)"
        }
    }
}

protocol FileSystem {
    func directoryExists(at url: URL) -> Bool
}

struct LocalFileSystem: FileSystem {
    private let fileManager = FileManager.default

    func directoryExists(at url: URL) -> Bool {
        var isDirectory = ObjCBool(false)
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
