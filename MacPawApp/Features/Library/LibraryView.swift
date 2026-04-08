import AppKit
import SwiftUI

struct LibraryView: View {
    @ObservedObject var viewModel: LibraryViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.models.isEmpty {
                ContentUnavailableView(
                    "No Local Models",
                    systemImage: "cube.transparent",
                    description: Text("Install a local LLM folder to start chatting.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $viewModel.selectedModelID) {
                    ForEach(viewModel.models) { model in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.displayName)
                                .font(.body.weight(.semibold))
                            Text(model.modelPath)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .tag(model.id)
                    }
                }
                .listStyle(.sidebar)
            }

            Divider()

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
            }

            HStack {
                Button("Install Local Model…") {
                    openInstallPanel()
                }

                Spacer()

                Button("Remove") {
                    Task {
                        try? await viewModel.removeSelectedModel()
                    }
                }
                .disabled(viewModel.selectedModel == nil)
            }
            .padding(12)
        }
        .navigationTitle("Models")
    }

    private func openInstallPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Install"
        panel.message = "Choose an already-downloaded local model folder."

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        Task {
            try? await viewModel.installModel(at: url)
        }
    }
}
