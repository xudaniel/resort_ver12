import SwiftUI

struct RootView: View {
    private enum Screen { case pick, compare, results }

    @StateObject private var engine = RankingEngine()
    @State private var screen: Screen = .pick

    var body: some View {
        NavigationStack {
            Group {
                switch screen {
                case .pick:
                    PickerView { images in
                        engine.load(images: images)
                        screen = .compare
                    }
                case .compare:
                    CompareView(engine: engine, onCancel: reset)
                        .onChange(of: engine.phase) { _, phase in
                            if phase == .done { screen = .results }
                        }
                case .results:
                    ResultsView(engine: engine, onRestart: reset)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var title: String {
        switch screen {
        case .pick: return "Pick Photos"
        case .compare: return "Compare"
        case .results: return "Top 3"
        }
    }

    private func reset() {
        // Release decoded images before returning to PickerView so memory
        // from the previous batch is freed before a new selection is loaded.
        engine.clear()
        screen = .pick
    }
}

#Preview { RootView() }
