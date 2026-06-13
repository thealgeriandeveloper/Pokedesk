import SwiftUI
import SwiftData

/// Home screen — "Pokedesk PRO" header with a list of collection cards.
struct CollectionsHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CardCollection.createdAt) private var collections: [CardCollection]

    @State private var showNewCollection = false
    @State private var addCardTarget: CardCollection?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.lg) {
                    ForEach(collections) { collection in
                        CollectionCard(
                            collection: collection,
                            onAddCards: { addCardTarget = collection }
                        )
                    }

                    createNewButton
                }
                .padding(.horizontal, Theme.Spacing.margin)
                .padding(.top, Theme.Spacing.xs)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .refreshable {
                await PriceRefreshService().refreshAll(context: context)
            }
            .background(Theme.Colors.background)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Pokedesk")
                        .font(Theme.Typography.displayLg)
                        .foregroundStyle(Theme.Colors.primaryDeep)
                    + Text(" PRO")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.Colors.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .sheet(isPresented: $showNewCollection) {
                CollectionFormView()
            }
            .sheet(item: $addCardTarget) { collection in
                CardSearchView(collection: collection)
            }
        }
    }

    private var createNewButton: some View {
        Button {
            showNewCollection = true
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .frame(width: 48, height: 48)
                    .background(Theme.Colors.surfaceContainer, in: Circle())
                Text("Create new collection")
                    .font(Theme.Typography.bodyLg)
                    .foregroundStyle(Theme.Colors.onSurface)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    .foregroundStyle(Theme.Colors.surfaceContainer)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A single collection card with title, total value and a 3-up preview row.
private struct CollectionCard: View {
    let collection: CardCollection
    let onAddCards: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            NavigationLink {
                CollectionDetailView(collection: collection)
            } label: {
                header
            }
            .buttonStyle(.plain)

            previewRow

            AddCardsButton(action: onAddCards)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .cardShadow()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .font(Theme.Typography.headlineSm)
                    .foregroundStyle(Theme.Colors.onSurface)
                Text("\(collection.itemCount) ITEMS")
                    .font(Theme.Typography.labelSm)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Total value")
                    .font(Theme.Typography.labelSm)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                MoneyLabel(amount: collection.totalValue, trend: collection.valueDelta)
            }
        }
    }

    private var previewRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            let preview = Array(collection.cards.prefix(3))
            ForEach(preview) { card in
                CardThumbnail(imageURL: card.imageURL, quantity: card.quantity, width: 92)
            }
            let remaining = collection.cards.count - preview.count
            if remaining > 0 {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Theme.Colors.surfaceLow)
                    .overlay {
                        Text("+\(remaining)")
                            .font(Theme.Typography.bodyLg)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    .frame(width: 92, height: 92 / 0.72)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    CollectionsHomeView()
        .modelContainer(PreviewData.container)
}
