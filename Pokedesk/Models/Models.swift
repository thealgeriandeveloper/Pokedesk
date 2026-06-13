import Foundation
import SwiftData

// MARK: - Collection

/// A user-defined grouping of owned cards (e.g. "V & Vstar group").
@Model
final class CardCollection {
    var id: UUID
    var name: String
    var detail: String
    var isDefault: Bool
    var createdAt: Date

    /// Owned cards belonging to this collection. Deleting the collection deletes its cards.
    @Relationship(deleteRule: .cascade, inverse: \OwnedCard.collection)
    var cards: [OwnedCard]

    init(name: String, detail: String = "", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.detail = detail
        self.isDefault = isDefault
        self.createdAt = .now
        self.cards = []
    }

    /// Total quantity of cards (counting duplicates).
    var itemCount: Int { cards.reduce(0) { $0 + $1.quantity } }

    /// Current market value = Σ (latest price × quantity).
    var totalValue: Double { cards.reduce(0) { $0 + $1.currentValue } }

    /// What the user paid for everything currently in the collection.
    var totalPaid: Double { cards.reduce(0) { $0 + $1.totalPaid } }

    /// Net value change since purchase.
    var valueDelta: Double { totalValue - totalPaid }
}

// MARK: - Owned card

/// A specific card the user owns, with quantity and what they paid.
@Model
final class OwnedCard {
    var id: UUID
    /// Identifier from the Pokémon TCG API (used to refresh prices).
    var apiCardId: String
    var name: String
    var setName: String
    var setNumber: String
    var rarity: String
    var imageURLString: String?

    var quantity: Int
    /// Price paid per single card.
    var pricePaid: Double

    /// Most recent market price per single card.
    var lastKnownPrice: Double
    var priceUpdatedAt: Date

    var collection: CardCollection?

    /// Price history points for the trend chart.
    @Relationship(deleteRule: .cascade, inverse: \PriceSnapshot.card)
    var snapshots: [PriceSnapshot]

    init(
        apiCardId: String,
        name: String,
        setName: String,
        setNumber: String,
        rarity: String,
        imageURLString: String? = nil,
        quantity: Int = 1,
        pricePaid: Double = 0,
        lastKnownPrice: Double = 0
    ) {
        self.id = UUID()
        self.apiCardId = apiCardId
        self.name = name
        self.setName = setName
        self.setNumber = setNumber
        self.rarity = rarity
        self.imageURLString = imageURLString
        self.quantity = quantity
        self.pricePaid = pricePaid
        self.lastKnownPrice = lastKnownPrice
        self.priceUpdatedAt = .now
        self.snapshots = []
    }

    var imageURL: URL? { imageURLString.flatMap(URL.init(string:)) }

    /// Current market value across all copies.
    var currentValue: Double { lastKnownPrice * Double(quantity) }

    /// Total amount paid across all copies.
    var totalPaid: Double { pricePaid * Double(quantity) }

    /// Per-card change since purchase, as a fraction (e.g. 0.12 = +12%).
    var changeFraction: Double {
        guard pricePaid > 0 else { return 0 }
        return (lastKnownPrice - pricePaid) / pricePaid
    }
}

// MARK: - Price snapshot

/// A historical market price point used to render the value trend chart.
@Model
final class PriceSnapshot {
    var id: UUID
    var price: Double
    var date: Date
    var card: OwnedCard?

    init(price: Double, date: Date) {
        self.id = UUID()
        self.price = price
        self.date = date
    }
}

// MARK: - Expense

enum ExpenseType: String, Codable, CaseIterable, Identifiable {
    case booster = "Booster"
    case etb = "ETB"
    case single = "Single card"
    case other = "Other"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .booster: return "shippingbox.fill"
        case .etb: return "square.stack.3d.up.fill"
        case .single: return "rectangle.on.rectangle.angled.fill"
        case .other: return "tag.fill"
        }
    }
}

/// A sealed-product or single-card purchase, used for spend/profit tracking.
@Model
final class Expense {
    var id: UUID
    var name: String
    var typeRaw: String
    /// Amount paid per unit.
    var amountPaid: Double
    var quantity: Int
    var purchaseDate: Date
    /// Optional current estimated value of the product (for sealed profit tracking).
    var estimatedValue: Double

    init(
        name: String,
        type: ExpenseType,
        amountPaid: Double,
        quantity: Int = 1,
        purchaseDate: Date = .now,
        estimatedValue: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.amountPaid = amountPaid
        self.quantity = quantity
        self.purchaseDate = purchaseDate
        self.estimatedValue = estimatedValue
    }

    var type: ExpenseType {
        get { ExpenseType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var totalPaid: Double { amountPaid * Double(quantity) }
    var totalEstimatedValue: Double { estimatedValue * Double(quantity) }

    /// Change since purchase as a fraction.
    var changeFraction: Double {
        guard amountPaid > 0 else { return 0 }
        return (estimatedValue - amountPaid) / amountPaid
    }
}
