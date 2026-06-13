import SwiftUI

// MARK: - Money formatting

enum Money {
    static func string(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

/// A bold price with an optional green/red trend arrow, e.g. `↗ $250.12`.
struct MoneyLabel: View {
    let amount: Double
    /// Positive → green up arrow, negative → red down arrow, nil → no arrow.
    var trend: Double? = nil
    var font: Font = Theme.Typography.priceMd

    private var isUp: Bool { (trend ?? 0) >= 0 }

    var body: some View {
        HStack(spacing: Theme.Spacing.base) {
            if trend != nil {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isUp ? Theme.Colors.positive : Theme.Colors.negative)
            }
            Text(Money.string(amount))
                .font(font)
                .foregroundStyle(Theme.Colors.onSurface)
        }
    }
}

/// Pokémon card artwork thumbnail with a dark quantity badge in the corner.
struct CardThumbnail: View {
    var imageURL: URL?
    var quantity: Int = 1
    /// Fixed width; when nil the thumbnail fills its container and keeps the card ratio.
    var width: CGFloat? = 96
    var aspectRatio: CGFloat = 0.72 // standard TCG card ratio

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Colors.surfaceContainer)
                .overlay {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .empty:
                            ProgressView().tint(Theme.Colors.primary)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        @unknown default:
                            Color.clear
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))

            if quantity > 1 {
                Text("x\(quantity)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.badge, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .padding(6)
            }
        }
        .modifier(ThumbnailSize(width: width, aspectRatio: aspectRatio))
    }
}

/// Applies either a fixed size or an aspect-ratio fill depending on whether width is set.
private struct ThumbnailSize: ViewModifier {
    let width: CGFloat?
    let aspectRatio: CGFloat

    func body(content: Content) -> some View {
        if let width {
            content.frame(width: width, height: width / aspectRatio)
        } else {
            content.aspectRatio(aspectRatio, contentMode: .fit)
        }
    }
}

/// Thin amber progress track for collection completion.
struct AmberProgressBar: View {
    /// 0...1
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.progressTrack)
                Capsule()
                    .fill(Theme.Colors.amberGradient)
                    .frame(width: geo.size.width * max(0, min(1, progress)))
            }
        }
        .frame(height: 6)
    }
}

/// Full-width amber gradient call-to-action button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.Colors.amberGradient, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Outlined "Add cards" style button on a light surface.
struct AddCardsButton: View {
    var title: String = "Add cards"
    var action: () -> Void

    var body: some View {
        PrimaryButton(title: title, systemImage: "plus.circle.fill", action: action)
    }
}

/// A selectable pill chip used for filters/segments (e.g. All / Boosters / ETB).
struct ChipToggle: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.labelSm)
                .foregroundStyle(isSelected ? .white : Theme.Colors.onSurface)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        Capsule().fill(Theme.Colors.amberGradient)
                    } else {
                        Capsule().fill(Theme.Colors.surface)
                            .overlay(Capsule().stroke(Theme.Colors.surfaceContainer, lineWidth: 1))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

/// Pill-shaped search field matching the mockups.
struct SearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Colors.secondaryLabel)
            TextField(placeholder, text: $text)
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Colors.onSurface)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, 14)
        .background(Theme.Colors.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.Colors.surfaceContainer, lineWidth: 1))
    }
}

/// Stepper with rounded +/- buttons used for quantity selection.
struct QuantityStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...999

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            stepButton(systemName: "minus") {
                if value > range.lowerBound { value -= 1 }
            }
            Text("\(value)")
                .font(Theme.Typography.headlineSm)
                .foregroundStyle(Theme.Colors.onSurface)
                .frame(minWidth: 24)
            stepButton(systemName: "plus") {
                if value < range.upperBound { value += 1 }
            }
        }
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.onSurface)
                .frame(width: 36, height: 36)
                .background(Theme.Colors.surface, in: Circle())
                .overlay(Circle().stroke(Theme.Colors.surfaceContainer, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
