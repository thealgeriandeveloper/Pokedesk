import SwiftUI
import SwiftData

/// Detail of one collection: searchable, grouped by set, with a value summary card.
struct CollectionDetailView: View {
    @Bindable var collection: CardCollection
    @Environment(\.modelContext) private var context

    @Environment(\.dismiss) private var dismiss

    @State private var search = ""
    @State private var showAddCard = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    /// Cards grouped by set name, filtered by the search query.
    private var groupedBySet: [(set: String, cards: [OwnedCard])] {
        let filtered = collection.cards.filter {
            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
        }
        let groups = Dictionary(grouping: filtered, by: \.setName)
        return groups
            .map { (set: $0.key, cards: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.set < $1.set }
    }

    private let columns = [GridItem(.flexible(), spacing: Theme.Spacing.sm),
                           GridItem(.flexible(), spacing: Theme.Spacing.sm),
                           GridItem(.flexible(), spacing: Theme.Spacing.sm)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                SearchField(placeholder: "Search any card…", text: $search)

                ForEach(groupedBySet, id: \.set) { group in
                    setSection(group.set, cards: group.cards)
                }

                if collection.cards.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, Theme.Spacing.margin)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .safeAreaInset(edge: .bottom) {
            AddCardsButton(action: { showAddCard = true })
                .padding(.horizontal, Theme.Spacing.margin)
                .padding(.bottom, Theme.Spacing.xs)
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(collection.name)
                        .font(Theme.Typography.headlineSm)
                        .foregroundStyle(Theme.Colors.onSurface)
                    Text("\(collection.itemCount) ITEMS")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    Button { showEdit = true } label: {
                        Image(systemName: "pencil")
                    }
                    Menu {
                        Button { showEdit = true } label: { Label("Edit collection", systemImage: "pencil") }
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Delete collection", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                .foregroundStyle(Theme.Colors.onSurface)
            }
        }
        .sheet(isPresented: $showAddCard) {
            CardSearchView(collection: collection)
        }
        .sheet(isPresented: $showEdit) {
            CollectionFormView(editing: collection)
        }
        .alert("Delete \u{201C}\(collection.name)\u{201D}?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                context.delete(collection)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the collection and all \(collection.itemCount) cards in it. This can't be undone.")
        }
    }

    // MARK: - Set section (header + summary card + grid)

    private func setSection(_ set: String, cards: [OwnedCard]) -> some View {
        let value = cards.reduce(0) { $0 + $1.currentValue }
        let owned = cards.count
        // A nominal "set completion" target for the progress bar.
        let target = 230
        let progress = Double(owned) / Double(target)

        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "bookmark.fill").foregroundStyle(Theme.Colors.primary)
                Text(set)
                    .font(Theme.Typography.headlineSm)
                    .foregroundStyle(Theme.Colors.onSurface)
            }

            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text("\(owned)/\(target) cards")
                        .font(Theme.Typography.labelSm)
                        .foregroundStyle(Theme.Colors.primaryDeep)
                    Spacer()
                    MoneyLabel(amount: value)
                }
                AmberProgressBar(progress: progress)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .cardShadow()

            LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                ForEach(cards) { card in
                    NavigationLink {
                        CardDetailView(card: card)
                    } label: {
                        CardCell(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text("No cards yet")
                .font(Theme.Typography.bodyLg)
                .foregroundStyle(Theme.Colors.onSurface)
            Text("Tap \u{201C}Add cards\u{201D} to start tracking value.")
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xl)
    }
}

/// A grid cell: card art, name, rarity, price.
private struct CardCell: View {
    let card: OwnedCard

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CardThumbnail(imageURL: card.imageURL, quantity: card.quantity, width: nil)
                .frame(maxWidth: .infinity)
            Text(card.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.Colors.onSurface)
                .lineLimit(1)
            Text(card.rarity)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(Money.string(card.lastKnownPrice))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.Colors.onSurface)
        }
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(collection: PreviewData.sampleCollection)
    }
    .modelContainer(PreviewData.container)
}
