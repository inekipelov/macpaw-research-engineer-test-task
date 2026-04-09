import SwiftUI

struct ChatView: View {
    let model: InstalledModel
    let onClose: () -> Void

    @StateObject private var viewModel: ChatViewModel

    init(model: InstalledModel, client: LLMChatClient, onClose: @escaping () -> Void) {
        self.model = model
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: ChatViewModel(model: model, client: client))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                TextField("Send a prompt to \(model.displayName)", text: $viewModel.prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.sendCurrentPrompt()
                    }

                HStack {
                    Text(viewModel.isStreaming ? "Streaming response…" : "Ready")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Send") {
                        viewModel.sendCurrentPrompt()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isStreaming)
                }
            }
            .padding(20)
        }
        .navigationTitle(model.displayName)
        .toolbar {
            ToolbarItem {
                Button("Close Chat", systemImage: "xmark.circle", action: onClose)
                    .help("Close the current chat and return to model setup")
            }
        }
        .onDisappear {
            viewModel.cancelStreaming()
        }
    }

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .assistant {
                bubble(message, background: Color(nsColor: .windowBackgroundColor))
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                bubble(message, background: Color.accentColor.opacity(0.16))
            }
        }
    }

    private func bubble(_ message: ChatMessage, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message.role == .assistant ? model.displayName : "You")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(message.text.isEmpty && message.role == .assistant ? "…" : message.text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(background)
        )
    }
}
