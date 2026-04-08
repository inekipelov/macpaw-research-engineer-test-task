import SwiftUI

struct ModelSetupView: View {
    let model: InstalledModel
    let onSave: (InstalledModel) async throws -> Void
    let onOpenChat: (InstalledModel) async throws -> Void

    @StateObject private var viewModel: ModelSetupViewModel
    @State private var statusMessage = "Advanced parameters are stored per model."
    @State private var isError = false
    @State private var isWorking = false

    init(
        model: InstalledModel,
        onSave: @escaping (InstalledModel) async throws -> Void,
        onOpenChat: @escaping (InstalledModel) async throws -> Void
    ) {
        self.model = model
        self.onSave = onSave
        self.onOpenChat = onOpenChat
        _viewModel = StateObject(wrappedValue: ModelSetupViewModel(model: model))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(model.displayName)
                .font(.largeTitle.weight(.bold))

            Text(model.modelPath)
                .font(.callout)
                .foregroundStyle(.secondary)

            Form {
                TextField("Max tokens", text: $viewModel.maxTokensText)
                TextField("Temperature", text: $viewModel.temperatureText)
                TextField("Top-p", text: $viewModel.topPText)
                TextField("Seed", text: $viewModel.seedText)
                TextField("Context window", text: $viewModel.contextWindowText)
            }
            .formStyle(.grouped)
            .frame(maxWidth: 420)

            if let validationMessage = viewModel.validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            Text(statusMessage)
                .foregroundStyle(isError ? .red : .secondary)

            HStack {
                Button("Save Parameters") {
                    Task {
                        await performSave()
                    }
                }
                .disabled(viewModel.validationMessage != nil || isWorking)

                Button("Open Chat") {
                    Task {
                        await performOpenChat()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.validationMessage != nil || isWorking)
            }

            Spacer()
        }
        .padding(24)
        .navigationTitle(model.displayName)
    }

    private func performSave() async {
        do {
            isWorking = true
            defer { isWorking = false }

            let updated = try viewModel.buildUpdatedModel()
            try await onSave(updated)
            statusMessage = "Saved advanced parameters for \(updated.displayName)."
            isError = false
        } catch {
            statusMessage = error.localizedDescription
            isError = true
        }
    }

    private func performOpenChat() async {
        do {
            isWorking = true
            defer { isWorking = false }

            let updated = try viewModel.buildUpdatedModel()
            try await onOpenChat(updated)
            statusMessage = "Opening chat for \(updated.displayName)."
            isError = false
        } catch {
            statusMessage = error.localizedDescription
            isError = true
        }
    }
}
