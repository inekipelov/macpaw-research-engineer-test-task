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
        let launchOptions = try LaunchOptions.make(arguments: arguments, fileSystem: fileSystem)
        guard let modelPath = launchOptions.initialModelPath else {
            throw CLIConfigurationError.missingRequiredOption("--model-path")
        }

        return launchOptions.configuration(for: modelPath)
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
            "topP: \(generationOptions.topP ?? 0.95)",
            "seed: \(generationOptions.seed.map(String.init) ?? "none")",
            "contextWindow: \(contextWindowOverride.map(String.init) ?? "none")"
        ].joined(separator: "\n")
    }

    static var usageText: String {
        """
        Usage: MacPawCLI [--model-path <path>] [options]

        Options:
          --model-path <path>       Local MLX model directory
          --max-tokens <int>        Maximum output tokens (default: 256)
          --temperature <double>    Sampling temperature (default: 0.7)
          --top-p <double>          Nucleus sampling value (default: 0.95)
          --seed <int>              Optional deterministic seed
          --context-window <int>    Optional context window override

        Chat commands:
          /help                     Show help
          /config                   Show effective configuration
          close                     Return to model selection
          /exit                     Exit the application
        """
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
