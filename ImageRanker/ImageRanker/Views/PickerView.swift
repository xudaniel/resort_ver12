import SwiftUI
import PhotosUI
import ImageIO

struct PickerView: View {
    let onReady: ([UIImage]) -> Void

    @State private var selection: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                Text("Select at least 3 photos")
                    .font(.headline)
                Text("You'll compare them in pairs to find your favorite three.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            PhotosPicker(selection: $selection, maxSelectionCount: 100, matching: .images) {
                Label("Choose Photos", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)

            if isLoading {
                ProgressView("Loading photos…")
            } else if !images.isEmpty {
                thumbnailStrip
                infoFooter
            }

            Spacer()
        }
        // .task(id:) automatically cancels the prior load when selection changes,
        // preventing stale-photo and stuck-spinner races.
        .task(id: selection) {
            if selection.isEmpty {
                images = []
                isLoading = false
                return
            }
            await loadImages(from: selection)
        }
    }

    // MARK: - Subviews

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var infoFooter: some View {
        VStack(spacing: 12) {
            Text("\(images.count) photos selected · ~\(estimatedComparisons(n: images.count)) comparisons needed")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button { onReady(images) } label: {
                Label("Start Comparing", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            .disabled(images.count < 3)
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Loading

    private func loadImages(from items: [PhotosPickerItem]) async {
        isLoading = true
        var loaded: [UIImage] = []
        for item in items {
            guard !Task.isCancelled else { return }
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = downsample(data: data, maxDimension: 800) {
                loaded.append(image)
            }
        }
        guard !Task.isCancelled else { return }
        images = loaded
        isLoading = false
    }

    /// Decodes at most maxDimension×maxDimension pixels using ImageIO.
    /// 800px gives ample quality for comparison cards while keeping
    /// 100-photo selections within ~256 MB of pixel buffer memory.
    private func downsample(data: Data, maxDimension: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func estimatedComparisons(n: Int) -> Int {
        guard n > 1 else { return 0 }
        let logN = Int(ceil(log2(Double(n))))
        return max(1, (n - 1) + 2 * logN - 1)
    }
}

#Preview { PickerView { _ in } }
