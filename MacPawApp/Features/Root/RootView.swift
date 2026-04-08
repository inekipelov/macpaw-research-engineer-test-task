import SwiftUI

struct RootViewState: Equatable {
    var models: [InstalledModel]
    var selectedModelID: UUID?
    var chattingModelID: UUID?

    var activeChatTitle: String? {
        guard chattingModelID == selectedModelID,
              let model = models.first(where: { $0.id == chattingModelID }) else {
            return nil
        }

        return model.displayName
    }
}

struct RootView: View {
    let environment: AppEnvironment

    @StateObject private var libraryViewModel: LibraryViewModel
    @State private var chattingModelID: UUID?

    init(environment: AppEnvironment) {
        self.environment = environment
        _libraryViewModel = StateObject(wrappedValue: LibraryViewModel(registry: environment.registry))
    }

    var body: some View {
        NavigationSplitView {
            LibraryView(viewModel: libraryViewModel)
        } detail: {
            detailView
        }
        .onChange(of: libraryViewModel.selectedModelID) { _, newValue in
            if newValue != chattingModelID {
                chattingModelID = nil
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        let state = RootViewState(
            models: libraryViewModel.models,
            selectedModelID: libraryViewModel.selectedModelID,
            chattingModelID: chattingModelID
        )

        if let selectedModel = libraryViewModel.selectedModel {
            if state.activeChatTitle != nil {
                ChatView(model: selectedModel, client: environment.chatClient)
                    .id(selectedModel.id)
            } else {
                ModelSetupView(
                    model: selectedModel,
                    onSave: { updatedModel in
                        _ = try await libraryViewModel.updateModel(updatedModel)
                    },
                    onOpenChat: { updatedModel in
                        var openedModel = updatedModel
                        openedModel.lastUsedAt = .now
                        let persisted = try await libraryViewModel.updateModel(openedModel)
                        chattingModelID = persisted.id
                    }
                )
                .id(selectedModel.id)
            }
        } else {
            ContentUnavailableView(
                "Select or Install a Model",
                systemImage: "bubble.left.and.text.bubble.right",
                description: Text("Choose an installed model from the sidebar or add a new local LLM folder.")
            )
        }
    }
}
