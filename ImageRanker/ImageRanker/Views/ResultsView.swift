import SwiftUI

struct ResultsView: View {
    @ObservedObject var engine: RankingEngine
    let onRestart: () -> Void

    private static let medals = ["🥇", "🥈", "🥉"]
    private static let ringColors: [Color] = [.yellow, .gray, .orange]

    var body: some View {
        VStack(spacing: 28) {
            Text("Your Top \(engine.result.count)")
                .font(.title2.bold())
                .padding(.top, 8)

            podium

            VStack(spacing: 12) {
                ForEach(Array(engine.result.enumerated()), id: \.offset) { rank, index in
                    rankRow(rank: rank, index: index)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onRestart) {
                Label("Start Over", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }

    private var podium: some View {
        let order: [Int] = {
            switch engine.result.count {
            case 3: return [1, 0, 2]
            case 2: return [1, 0]
            default: return [0]
            }
        }()
        return HStack(alignment: .bottom, spacing: 16) {
            ForEach(order, id: \.self) { rank in podiumItem(rank: rank) }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func podiumItem(rank: Int) -> some View {
        if engine.result.indices.contains(rank) {
            let index = engine.result[rank]
            let size: CGFloat = rank == 0 ? 140 : 104
            let color = Self.ringColors[rank]
            VStack(spacing: 8) {
                Text(Self.medals[rank]).font(.system(size: rank == 0 ? 40 : 30))
                if engine.images.indices.contains(index) {
                    Image(uiImage: engine.images[index])
                        .resizable().scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(color, lineWidth: 4))
                        .shadow(radius: 4)
                }
            }
        }
    }

    private func rankRow(rank: Int, index: Int) -> some View {
        HStack(spacing: 14) {
            Text(Self.medals[rank]).font(.title3).frame(width: 32)
            if engine.images.indices.contains(index) {
                Image(uiImage: engine.images[index])
                    .resizable().scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Text("Rank #\(rank + 1)").font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}
