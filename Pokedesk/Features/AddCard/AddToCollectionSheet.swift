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

                Spacer()

                PrimaryButton(title: "Add to Collection", systemImage: "plus.circle.fill") { save() }
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
        }
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
        let card = OwnedCard(
            apiCardId: apiCard.id,
            name: apiCard.name,
            setName: apiCard.setName,
            setNumber: apiCard.number.hasPrefix("#") ? apiCard.number : "#\(apiCard.number)",
            rarity: apiCard.rarity,
            imageURLString: apiCard.imageURLString,
            quantity: quantity,
            pricePaid: pricePaid,
            lastKnownPrice: apiCard.marketPrice ?? pricePaid
        )
        card.collection = collection
        collection.cards.append(card)
        // Seed an initial price point so the trend chart has data.
        let snapshot = PriceSnapshot(price: card.lastKnownPrice, date: .now)
        snapshot.card = card
        card.snapshots.append(snapshot)
        context.insert(card)
        try? context.save()
        dismiss()
        onSaved()
    }
}
