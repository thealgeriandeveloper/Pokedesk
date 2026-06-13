import SwiftUI
import SwiftData

/// Bottom sheet to confirm quantity and price paid before saving a card.
struct AddToCollectionSheet: View {
    let apiCard: APICard
    let collection: CardCollection
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var quantity = 1
    @State private var pricePaidText: String = ""
    @State private var selectedCollections: Set<CardCollection> = []

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                cardRow

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Text("Quantity")
                            .font(Theme.Typography.bodyLg)
                            .foregroundStyle(Theme.Colors.onSurface)
                        Spacer()
                        QuantityStepper(value: $quantity)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Price paid (per card)")
                        .font(Theme.Typography.bodyLg)
                        .foregroundStyle(Theme.Colors.onSurface)
                    HStack {
                        Text("$").foregroundStyle(Theme.Colors.secondaryLabel)
                        TextField(defaultPriceString, text: $pricePaidText)
                            .keyboardType(.decimalPad)
                            .font(Theme.Typography.bodyLg)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.Colors.surfaceContainer, lineWidth: 1))
                }

                collectionsRow

                Spacer()

                PrimaryButton(title: saveTitle, systemImage: "plus.circle.fill") { save() }
                    .disabled(selectedCollections.isEmpty)
                    .opacity(selectedCollections.isEmpty ? 0.5 : 1)
            }
            .padding(Theme.Spacing.margin)
            .background(Theme.Colors.background)
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .onAppear {
                if selectedCollections.isEmpty { selectedCollections = [collection] }
            }
        }
    }

    /// Navigable row showing how many collections are selected.
    private var collectionsRow: some View {
        NavigationLink {
            CollectionPickerView(selection: $selectedCollections)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Collections")
                        .font(Theme.Typography.bodyLg)
                        .foregroundStyle(Theme.Colors.onSurface)
                    Text(selectionSummary)
                        .font(Theme.Typography.labelSm)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.Colors.surfaceContainer, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var selectionSummary: String {
        switch selectedCollections.count {
        case 0: return "None selected"
        case 1: return selectedCollections.first?.name ?? "1 collection"
        default: return "\(selectedCollections.count) collections"
        }
    }

    private var saveTitle: String {
        selectedCollections.count > 1 ? "Add to \(selectedCollections.count) collections" : "Add to Collection"
    }

    private var cardRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            CardThumbnail(imageURL: apiCard.imageURL, quantity: 1, width: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(apiCard.name)
                    .font(Theme.Typography.headlineSm)
                    .foregroundStyle(Theme.Colors.onSurface)
                if let price = apiCard.marketPrice {
                    HStack(spacing: 4) {
                        Text(Money.string(price))
                            .font(Theme.Typography.priceMd)
                            .foregroundStyle(Theme.Colors.onSurface)
                        Text("Market Price")
                            .font(Theme.Typography.labelSm)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                Text("\(apiCard.setName) · #\(apiCard.number)")
                    .font(Theme.Typography.labelSm)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceLow, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
    }

    private var defaultPriceString: String {
        apiCard.marketPrice.map { String(format: "%.2f", $0) } ?? "0.00"
    }

    private func save() {
        let pricePaid = Double(pricePaidText.replacingOccurrences(of: ",", with: ".")) ?? apiCard.marketPrice ?? 0
        let setNumber = apiCard.number.hasPrefix("#") ? apiCard.number : "#\(apiCard.number)"

        // Add an independent copy of the card to each selected collection.
        for target in selectedCollections {
            let card = OwnedCard(
                apiCardId: apiCard.id,
                name: apiCard.name,
                setName: apiCard.setName,
                setNumber: setNumber,
                rarity: apiCard.rarity,
                imageURLString: apiCard.imageURLString,
                quantity: quantity,
                pricePaid: pricePaid,
                lastKnownPrice: apiCard.marketPrice ?? pricePaid
            )
            card.collection = target
            target.cards.append(card)
            // Seed an initial price point so the trend chart has data.
            let snapshot = PriceSnapshot(price: card.lastKnownPrice, date: .now)
            snapshot.card = card
            card.snapshots.append(snapshot)
            context.insert(card)
        }
        try? context.save()
        dismiss()
        onSaved()
    }
}
