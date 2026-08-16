import SwiftUI

struct CompareView: View {
    @ObservedObject var engine: RankingEngine
    let onCancel: () -> Void

    @State private var pickedIndex: Int?

    var body: some View {
        VStack(spacing: 16) {
            progressBar

            if let pair = engine.currentPair {
                HStack(spacing: 12) {
                    card(for: pair.left)
                    card(for: pair.right)
                }
                .padding(.horizontal, 16)
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }

            Text("Tap the photo you like better")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Cancel", role: .destructive, action: onCancel)
                .padding(.bottom, 8)
        }
        .padding(.top, 8)
    }

    private var progressBar: some View {
        let done = engine.progress.done
        let total = max(engine.progress.total, 1)
        let fraction = min(1.0, Double(done) / Double(total))

        return VStack(spacing: 6) {
            HStack {
                Text("Round \(done + 1) of ~\(total)")
                Spacer()
                Text("\(Int(fraction * 100))%")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Capsule()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * fraction)
                            .animation(.easeInOut(duration: 0.3), value: fraction)
                    }
                }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func card(for index: Int) -> some View {
        let isPicked = pickedIndex == index
        let isDimmed = pickedIndex != nil && !isPicked

        ZStack(alignment: .topTrailing) {
            if engine.images.indices.contains(index) {
                // scaledToFit shows the complete photo — fill would crop
                // landscape images to a narrow center strip.
                Image(uiImage: engine.images[index])
                    .resizable()
                    .scaledToFit()
            }
            if isPicked {
                Label("Best!", systemImage: "star.fill")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
                    .padding(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(isPicked ? Color.accentColor : Color.clear, lineWidth: 4))
        .opacity(isDimmed ? 0.4 : 1.0)
        .scaleEffect(isPicked ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: pickedIndex)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { handleTap(picked: index) }
    }

    private func handleTap(picked: Int) {
        guard let pair = engine.currentPair, pickedIndex == nil else { return }
        pickedIndex = picked
        let other = (pair.left == picked) ? pair.right : pair.left
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            engine.pick(winner: picked, loser: other)
            pickedIndex = nil
        }
    }
}
