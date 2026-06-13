import SwiftUI
import SwiftData

/// Multi-select list of collections used to add a card to several at once.
/// Mirrors the "pick collection" mockup: a create-new row on top, then a
/// checkable list with per-collection card counts.
struct CollectionPickerView: View {
    /// The set of collections the card will be added to.
    @Binding var selection: Set<CardCollection>

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CardCollection.createdAt) private var collections: [CardCollection]
    @State private var showNewCollection = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.sm) {
                createNewRow

                ForEach(collections) { collection in
                    row(for: collection)
                }
            }
            .padding(.horizontal, Theme.Spacing.margin)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Collection")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Save changes", systemImage: "checkmark") { dismiss() }
                .padding(.horizontal, Theme.Spacing.margin)
                .padding(.bottom, Theme.Spacing.xs)
        }
        .sheet(isPresented: $showNewCollection) {
            CollectionFormView()
        }
    }

    private var createNewRow: some View {
        Button { showNewCollection = true } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "folder.badge.plus")
                    .foregroundStyle(Theme.Colors.primary)
                Text("Create new collection")
                    .font(Theme.Typography.bodyLg)
                    .foregroundStyle(Theme.Colors.onSurface)
                Spacer()
                Image(systemName: "plus")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(Theme.Colors.outlineVariant)
            )
        }
        .buttonStyle(.plain)
    }

    private func row(for collection: CardCollection) -> some View {
        let isSelected = selection.contains(collection)
        return Button {
            if isSelected { selection.remove(collection) } else { selection.insert(collection) }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryLabel)

                VStack(alignment: .leading, spacing: 2) {
                    Text(collection.name)
                        .font(Theme.Typography.bodyLg)
                        .foregroundStyle(Theme.Colors.onSurface)
                    Text("\(collection.cards.count) cards")
                        .font(Theme.Typography.labelSm)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                if collection.isDefault {
                    Text("Default")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.Colors.primaryDeep)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Theme.Colors.progressTrack, in: Capsule())
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}
