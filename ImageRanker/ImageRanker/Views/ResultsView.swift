import SwiftUI

struct ResultsView: View {
    @ObservedObject var engine: RankingEngine
    let onRestart: () -> Void

    private static let medals = ["🥇", "🥈", "🥉"]
    private static let ringColors: [Color] = [.yellow, .gray, .orange]

    var body: some View {
        // ScrollView lets the rank list and restart button remain reachable
        // on compact landscape heights (~300pt) where the podium alone would
        // fill most of the available space.
        ScrollView {
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
    }

    /// Adaptive podium: sizes scale with available width and are capped by
    /// the available height so wide windows (iPad, landscape) don't produce
    /// oversized circles that overflow the GeometryReader frame.
    private var podium: some View {
        let order: [Int] = {
            switch engine.result.count {
            case 3: return [1, 0, 2]
            case 2: return [1, 0]
            default: return [0]
            }
        }()

        return GeometryReader { geo in
            let hPadding: CGFloat = 24
            let spacing: CGFloat = 16
            let count = CGFloat(order.count)
            let available = geo.size.width - 2 * hPadding - spacing * (count - 1)
            // First-place item is 1.35× wider/taller than the others.
            let hasFirst = order.contains(0)
            let firstMult: CGFloat = hasFirst ? 1.35 : 1.0
            let otherCount = CGFloat(order.filter { $0 != 0 }.count)
            let unitFromWidth = available / (otherCount + firstMult * (hasFirst ? 1 : 0))
            // Reserve ~55pt for medal emoji + VStack spacing above the image circle;
            // this prevents firstSize from exceeding the GeometryReader height on wide
            // screens (e.g. iPad) where width-only sizing yields 300–400pt values.
            let maxFirstSize = max(0, geo.size.height - 55)
            let unit = min(unitFromWidth, maxFirstSize / firstMult)
            let firstSize = unit * firstMult

            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(order, id: \.self) { rank in
                    podiumItem(rank: rank, size: rank == 0 ? firstSize : unit)
                }
            }
            .padding(.horizontal, hPadding)
        }
        .frame(height: 220)
    }

    @ViewBuilder
    private func podiumItem(rank: Int, size: CGFloat) -> some View {
        if engine.result.indices.contains(rank) {
            let index = engine.result[rank]
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
