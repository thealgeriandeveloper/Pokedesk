import Foundation
import SwiftData

/// Seeds the store with demo collections, cards and expenses on first launch,
/// so the app mirrors the design mockups out of the box.
enum SampleData {

    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<CardCollection>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }
        seed(context)
    }

    static func seed(_ context: ModelContext) {
        // MARK: Collection 1 — V & Vstar group
        let vstar = CardCollection(name: "V & Vstar group", detail: "Sword and Shield", isDefault: true)

        let charizard = OwnedCard(
            apiCardId: "swsh9-154",
            name: "Charizard V",
            setName: "Brilliant Stars",
            setNumber: "#154",
            rarity: "Basic",
            imageURLString: "https://images.pokemontcg.io/swsh9/154_hires.png",
            quantity: 2, pricePaid: 95.00, lastKnownPrice: 139.18
        )
        let arceus = OwnedCard(
            apiCardId: "swsh9-123",
            name: "Arceus VSTAR",
            setName: "Brilliant Stars",
            setNumber: "#123",
            rarity: "VSTAR",
            imageURLString: "https://images.pokemontcg.io/swsh9/123_hires.png",
            quantity: 1, pricePaid: 70.00, lastKnownPrice: 85.50
        )
        let lumineon = OwnedCard(
            apiCardId: "swsh9-040",
            name: "Lumineon V",
            setName: "Brilliant Stars",
            setNumber: "#040",
            rarity: "Basic",
            imageURLString: "https://images.pokemontcg.io/swsh9/40_hires.png",
            quantity: 4, pricePaid: 9.00, lastKnownPrice: 12.00
        )
        vstar.cards = [charizard, arceus, lumineon]

        // MARK: Collection 2 — Vintage Base Set
        let vintage = CardCollection(name: "Vintage Base Set", detail: "Base")
        let baseCharizard = OwnedCard(
            apiCardId: "base1-4",
            name: "Charizard",
            setName: "Base Set",
            setNumber: "#4",
            rarity: "Rare Holo",
            imageURLString: "https://images.pokemontcg.io/base1/4_hires.png",
            quantity: 1, pricePaid: 1500.00, lastKnownPrice: 1420.00
        )
        let blastoise = OwnedCard(
            apiCardId: "base1-2",
            name: "Blastoise",
            setName: "Base Set",
            setNumber: "#2",
            rarity: "Rare Holo",
            imageURLString: "https://images.pokemontcg.io/base1/2_hires.png",
            quantity: 1, pricePaid: 400.00, lastKnownPrice: 380.00
        )
        vintage.cards = [baseCharizard, blastoise]

        context.insert(vstar)
        context.insert(vintage)

        // Attach a price history to each card for the trend chart.
        for card in vstar.cards + vintage.cards {
            attachSnapshots(to: card, context: context)
        }

        // MARK: Expenses
        let expenses = [
            Expense(name: "Brilliant Stars ETB", type: .etb, amountPaid: 55.00, quantity: 1,
                    purchaseDate: date("2023-10-12"), estimatedValue: 85.00),
            Expense(name: "Crown Zenith Booster Box", type: .booster, amountPaid: 140.00, quantity: 1,
                    purchaseDate: date("2023-09-28"), estimatedValue: 165.00),
            Expense(name: "Charizard VMAX Single", type: .single, amountPaid: 115.00, quantity: 1,
                    purchaseDate: date("2023-08-15"), estimatedValue: 95.00),
            Expense(name: "Pikachu Illustrator", type: .other, amountPaid: 5.00, quantity: 1,
                    purchaseDate: date("2022-01-01"), estimatedValue: 5.50)
        ]
        expenses.forEach(context.insert)

        try? context.save()
    }

    /// Generate ~6 months of plausible price history ending at the card's current price.
    private static func attachSnapshots(to card: OwnedCard, context: ModelContext) {
        let months = 6
        let end = card.lastKnownPrice
        let start = card.pricePaid > 0 ? card.pricePaid : end * 0.8
        for i in 0...months {
            let t = Double(i) / Double(months)
            // Ease toward the end value with a small mid-bump for a natural curve.
            let bump = sin(t * .pi) * end * 0.12
            let price = start + (end - start) * t + bump
            let day = Calendar.current.date(byAdding: .month, value: -(months - i), to: .now) ?? .now
            let snapshot = PriceSnapshot(price: max(0, price), date: day)
            snapshot.card = card
            card.snapshots.append(snapshot)
            context.insert(snapshot)
        }
    }

    private static func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string) ?? .now
    }
}
