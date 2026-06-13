import SwiftUI
import PhotosUI

/// Scan-a-card flow: camera capture → on-device OCR → API match → confirm/choose.
/// Calls `onPicked` with the chosen card (the caller adds it to a collection),
/// or `onSearchManually` to fall back to text search.
struct CardScanView: View {
    var onPicked: (APICard) -> Void
    var onSearchManually: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraController()

    @State private var phase: Phase = .scanning
    @State private var candidates: [RankedCard] = []
    @State private var photoItem: PhotosPickerItem?

    private let recognizer = CardRecognizer()

    enum Phase {
        case scanning
        case identifying(UIImage)
        case confirm(RankedCard)
        case choose([RankedCard])
        case noMatch
    }

    var body: some View {
        ZStack {
            switch phase {
            case .scanning:
                ScanCameraScreen(
                    camera: camera,
                    photoItem: $photoItem,
                    onClose: { dismiss() },
                    onCapture: capture
                )
            case .identifying(let image):
                IdentifyingScreen(image: image, onCancel: { phase = .scanning })
            case .confirm(let match):
                ScanConfirmScreen(
                    match: match,
                    hasAlternatives: candidates.count > 1,
                    onConfirm: { finish(with: match.card) },
                    onSeeOthers: { phase = .choose(candidates) },
                    onBack: { phase = .scanning }
                )
            case .choose(let list):
                ScanChooseScreen(
                    candidates: list,
                    onConfirm: { finish(with: $0) },
                    onBack: { phase = .scanning }
                )
            case .noMatch:
                ScanNoMatchScreen(
                    onSearch: { onSearchManually() },
                    onBack: { phase = .scanning }
                )
            }
        }
        .task { await camera.prepare() }
        .onDisappear { camera.stop() }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadFromLibrary(newItem) }
        }
    }

    // MARK: - Actions

    private func capture() {
        Task {
            guard let image = await camera.capturePhoto() else { return }
            await identify(image)
        }
    }

    private func loadFromLibrary(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await identify(image)
    }

    private func identify(_ image: UIImage) async {
        phase = .identifying(image)
        let ranked = await recognizer.rankedMatches(for: image)
        candidates = ranked

        guard let best = ranked.first else { phase = .noMatch; return }
        let confident = best.confidence >= 0.85
            && (ranked.count == 1 || best.confidence - ranked[1].confidence >= 0.15)
        phase = confident ? .confirm(best) : .choose(ranked)
    }

    private func finish(with card: APICard) {
        camera.stop()
        onPicked(card)
    }
}
