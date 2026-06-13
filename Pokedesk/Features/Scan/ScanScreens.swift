import SwiftUI
import PhotosUI

// MARK: - 1. Camera

/// Dark camera screen with a card-shaped frame guide, capture and library buttons.
struct ScanCameraScreen: View {
    @ObservedObject var camera: CameraController
    @Binding var photoItem: PhotosPickerItem?
    var onClose: () -> Void
    var onCapture: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.isConfigured {
                CameraPreview(session: camera.session).ignoresSafeArea()
            }

            // Dim overlay + frame guide
            VStack {
                Spacer()
                CardFrameGuide(unavailable: camera.isUnavailable)
                    .padding(.horizontal, 40)
                Spacer()
            }

            VStack {
                topBar
                Spacer()
                controls
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            circleButton("xmark", action: onClose)
            Spacer()
            circleButton("bolt.slash.fill", action: {})
        }
        .padding(.horizontal, Theme.Spacing.margin)
        .padding(.top, Theme.Spacing.xs)
    }

    private var controls: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("SCAN MODE")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.primary)
                .padding(.horizontal, 16).padding(.vertical, 6)
                .overlay(Capsule().stroke(Theme.Colors.primary, lineWidth: 1.5))

            HStack {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer()

                Button(action: onCapture) {
                    ZStack {
                        Circle().fill(Theme.Colors.amberGradient).frame(width: 76, height: 76)
                        Image(systemName: "camera.fill").font(.title2).foregroundStyle(.white)
                    }
                    .overlay(Circle().stroke(.white, lineWidth: 4).frame(width: 88, height: 88))
                    .shadow(color: Theme.Colors.primary.opacity(0.6), radius: 16)
                }
                .disabled(!camera.isConfigured)
                .opacity(camera.isConfigured ? 1 : 0.4)

                Spacer()

                // Symmetry spacer to center the capture button
                Color.clear.frame(width: 52, height: 52)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding(.bottom, Theme.Spacing.xl)
    }

    private func circleButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.2), in: Circle())
        }
    }
}

/// The amber-cornered, card-shaped alignment guide.
private struct CardFrameGuide: View {
    var unavailable: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.06))
                .aspectRatio(0.72, contentMode: .fit)
                .overlay(CornerBrackets())

            Text(unavailable ? "Camera unavailable — use your photo library" : "Align the card inside the frame")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.black.opacity(0.55), in: Capsule())
                .padding(.horizontal, 12)
        }
    }
}

/// Amber L-shaped brackets in the four corners of the frame.
private struct CornerBrackets: View {
    var body: some View {
        GeometryReader { geo in
            let len = 36.0, lw = 5.0
            let w = geo.size.width, h = geo.size.height
            Path { p in
                // top-left
                p.move(to: CGPoint(x: 0, y: len)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: len, y: 0))
                // top-right
                p.move(to: CGPoint(x: w - len, y: 0)); p.addLine(to: CGPoint(x: w, y: 0)); p.addLine(to: CGPoint(x: w, y: len))
                // bottom-left
                p.move(to: CGPoint(x: 0, y: h - len)); p.addLine(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: len, y: h))
                // bottom-right
                p.move(to: CGPoint(x: w - len, y: h)); p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: w, y: h - len))
            }
            .stroke(Theme.Colors.primary, style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
            .shadow(color: Theme.Colors.primary.opacity(0.8), radius: 6)
        }
    }
}

// MARK: - 2. Identifying

/// Captured photo with an animated scanning line while we match it.
struct IdentifyingScreen: View {
    let image: UIImage
    var onCancel: () -> Void
    @State private var scanY: CGFloat = -1

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(uiImage: image)
                .resizable().scaledToFit()
                .frame(maxHeight: 340)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                .overlay(CornerBracketsOverlay())
                .overlay(scanLine)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                .padding(.horizontal, Theme.Spacing.xl)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Identifying card…")
                    .font(Theme.Typography.headlineMd)
                    .foregroundStyle(Theme.Colors.onSurface)
                HStack(spacing: Theme.Spacing.xs) {
                    Circle().fill(Theme.Colors.primary).frame(width: 8, height: 8)
                    Text("Matching against the Pokémon database")
                        .font(Theme.Typography.bodyMd)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .padding(.horizontal, Theme.Spacing.md).padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.surface, in: Capsule())
                .cardShadow()
            }

            Spacer()
            Button("Cancel", action: onCancel)
                .font(Theme.Typography.bodyLg)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                scanY = 1
            }
        }
    }

    private var scanLine: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Theme.Colors.primary, .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 3)
                .shadow(color: Theme.Colors.primary, radius: 8)
                .offset(y: (scanY * 0.5 + 0.5) * geo.size.height)
        }
    }
}

private struct CornerBracketsOverlay: View {
    var body: some View { CornerBrackets().padding(8) }
}

// MARK: - 3. Confirm match

struct ScanConfirmScreen: View {
    let match: RankedCard
    var hasAlternatives: Bool
    var onConfirm: () -> Void
    var onSeeOthers: () -> Void
    var onBack: () -> Void

    private var card: APICard { match.card }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            header

            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    CardThumbnail(imageURL: card.imageURL, quantity: 1, width: 220)
                        .cardShadow()
                        .padding(.top, Theme.Spacing.md)

                    HStack(spacing: 6) {
                        Text(card.name).font(Theme.Typography.headlineMd)
                            .foregroundStyle(Theme.Colors.onSurface)
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.Colors.primary)
                    }
                    Text("\(card.rarity)  ·  #\(card.number) \(card.setName)")
                        .font(Theme.Typography.bodyMd)
                        .foregroundStyle(Theme.Colors.secondaryLabel)

                    if let price = card.marketPrice {
                        VStack(spacing: 2) {
                            Text("EST. MARKET VALUE")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                            Text(Money.string(price))
                                .font(Theme.Typography.displayLg)
                                .foregroundStyle(Theme.Colors.onSurface)
                        }
                        .padding(Theme.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.surfaceLow, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                        .padding(.horizontal, Theme.Spacing.margin)
                    }
                }
            }

            VStack(spacing: Theme.Spacing.sm) {
                PrimaryButton(title: "Confirm & add", systemImage: "checkmark.circle.fill", action: onConfirm)
                if hasAlternatives {
                    Button("Not a match? See other results", action: onSeeOthers)
                        .font(Theme.Typography.bodyMd)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .padding(.horizontal, Theme.Spacing.margin)
            .padding(.bottom, Theme.Spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.amberGradient.opacity(0.18).ignoresSafeArea())
    }

    private var header: some View {
        ZStack {
            Text("Is this your card?")
                .font(Theme.Typography.headlineSm)
                .foregroundStyle(Theme.Colors.onSurface)
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left").font(.title3) }
                    .foregroundStyle(Theme.Colors.onSurface)
                Spacer()
                ConfidenceBadge(confidence: match.confidence)
            }
        }
        .padding(.horizontal, Theme.Spacing.margin)
        .padding(.top, Theme.Spacing.sm)
    }
}

/// Amber "98% match" pill.
struct ConfidenceBadge: View {
    let confidence: Double
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
            Text("\(Int((confidence * 100).rounded()))% match")
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(Theme.Colors.primaryDeep)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Theme.Colors.progressTrack, in: Capsule())
    }
}

// MARK: - 4. Choose the right card

struct ScanChooseScreen: View {
    let candidates: [RankedCard]
    var onConfirm: (APICard) -> Void
    var onBack: () -> Void

    @State private var selectedID: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("We found multiple matches for your scan. Select the exact version below.")
                        .font(Theme.Typography.bodyMd)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(.bottom, Theme.Spacing.xs)

                    ForEach(candidates) { candidate in
                        row(candidate)
                    }
                }
                .padding(Theme.Spacing.margin)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Confirm selection", systemImage: "arrow.right") {
                if let id = selectedID, let pick = candidates.first(where: { $0.id == id }) {
                    onConfirm(pick.card)
                }
            }
            .disabled(selectedID == nil)
            .opacity(selectedID == nil ? 0.5 : 1)
            .padding(.horizontal, Theme.Spacing.margin)
            .padding(.bottom, Theme.Spacing.xs)
        }
        .onAppear { selectedID = candidates.first?.id }
    }

    private var header: some View {
        ZStack {
            Text("Choose the right card")
                .font(Theme.Typography.headlineSm)
                .foregroundStyle(Theme.Colors.onSurface)
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left").font(.title3) }
                    .foregroundStyle(Theme.Colors.primaryDeep)
                Spacer()
            }
        }
        .padding(.horizontal, Theme.Spacing.margin)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.surface)
    }

    private func row(_ candidate: RankedCard) -> some View {
        let isSelected = selectedID == candidate.id
        let card = candidate.card
        return Button { selectedID = candidate.id } label: {
            HStack(spacing: Theme.Spacing.md) {
                CardThumbnail(imageURL: card.imageURL, quantity: 1, width: 56)
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.name)
                        .font(Theme.Typography.bodyLg)
                        .foregroundStyle(Theme.Colors.onSurface)
                    Text("\(card.setName) · #\(card.number)")
                        .font(Theme.Typography.labelSm)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    HStack(spacing: Theme.Spacing.xs) {
                        if let price = card.marketPrice {
                            Text(Money.string(price))
                                .font(Theme.Typography.priceMd)
                                .foregroundStyle(Theme.Colors.onSurface)
                        }
                        Text("\(Int((candidate.confidence * 100).rounded()))% match")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(isSelected ? Theme.Colors.primary : .clear, lineWidth: 2)
            )
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 5. No match

struct ScanNoMatchScreen: View {
    var onSearch: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Choose the right card")
                    .font(Theme.Typography.headlineSm)
                    .foregroundStyle(Theme.Colors.onSurface)
                HStack {
                    Button(action: onBack) { Image(systemName: "chevron.left").font(.title3) }
                        .foregroundStyle(Theme.Colors.onSurface)
                    Spacer()
                }
            }
            .padding(.horizontal, Theme.Spacing.margin)
            .padding(.vertical, Theme.Spacing.sm)

            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 130, height: 130)
                .background(Theme.Colors.surfaceContainer, in: Circle())

            Text("No match found")
                .font(Theme.Typography.headlineMd)
                .foregroundStyle(Theme.Colors.onSurface)
                .padding(.top, Theme.Spacing.lg)
            Text("We couldn't identify this card. Try searching manually to add it to your collection.")
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.xs)

            Spacer()
            PrimaryButton(title: "Search by name", systemImage: "keyboard", action: onSearch)
                .padding(.horizontal, Theme.Spacing.margin)
                .padding(.bottom, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
}
