import SwiftUI

struct ModelSetupView: View {
    let model: InstalledModel
    let onOpenChat: (InstalledModel) async throws -> Void

    @StateObject private var viewModel: ModelSetupViewModel
    @State private var statusMessage = "Response style is stored per model."
    @State private var isError = false
    @State private var isWorking = false

    init(
        model: InstalledModel,
        onOpenChat: @escaping (InstalledModel) async throws -> Void
    ) {
        self.model = model
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
                Picker("Response style", selection: $viewModel.selectedPreset) {
                    ForEach(ModelPreset.allCases, id: \.self) { preset in
                        Text(preset.title).tag(preset)
                    }
                }

                Text(viewModel.presetSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .frame(maxWidth: 420)

            Text(statusMessage)
                .foregroundStyle(isError ? .red : .secondary)

            HStack {
                Button("Open Chat") {
                    Task {
                        await performOpenChat()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isWorking)
            }

            Spacer()
        }
        .padding(24)
        .navigationTitle(model.displayName)
    }

    private func performOpenChat() async {
        do {
            isWorking = true
            defer { isWorking = false }

            let updated = viewModel.buildUpdatedModel()
            try await onOpenChat(updated)
            statusMessage = "Opening chat for \(updated.displayName) with the \(updated.generationPreset.title) preset."
            isError = false
        } catch {
            statusMessage = error.localizedDescription
            isError = true
        }
    }
}
