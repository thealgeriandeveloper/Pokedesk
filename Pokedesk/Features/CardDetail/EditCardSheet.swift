import SwiftUI
import SwiftData

/// Edit an owned card's quantity and the price paid per copy.
struct EditCardSheet: View {
    @Bindable var card: OwnedCard

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var quantity = 1
    @State private var pricePaidText = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header

                HStack {
                    Text("Quantity")
                        .font(Theme.Typography.bodyLg)
                        .foregroundStyle(Theme.Colors.onSurface)
                    Spacer()
                    QuantityStepper(value: $quantity)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                .cardShadow()

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Price paid (per card)")
                        .font(Theme.Typography.labelSm)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    HStack {
                        Text("$").foregroundStyle(Theme.Colors.secondaryLabel)
                        TextField("0.00", text: $pricePaidText)
                            .keyboardType(.decimalPad)
                            .font(Theme.Typography.bodyLg)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.Colors.surfaceContainer, lineWidth: 1))
                }

                Spacer()

                PrimaryButton(title: "Save changes", systemImage: "checkmark") { save() }
            }
            .padding(Theme.Spacing.margin)
            .background(Theme.Colors.background)
            .navigationTitle("Edit card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .onAppear {
                quantity = card.quantity
                pricePaidText = String(format: "%.2f", card.pricePaid)
            }
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            CardThumbnail(imageURL: card.imageURL, quantity: 1, width: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(Theme.Typography.headlineSm)
                    .foregroundStyle(Theme.Colors.onSurface)
                Text("\(card.setName) · \(card.setNumber)")
                    .font(Theme.Typography.labelSm)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
    }

    private func save() {
        card.quantity = max(1, quantity)
        if let price = Double(pricePaidText.replacingOccurrences(of: ",", with: ".")) {
            card.pricePaid = price
        }
        try? context.save()
        dismiss()
    }
}
