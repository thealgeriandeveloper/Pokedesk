import Foundation
import SwiftData

/// Refreshes market prices for owned cards from the Pokémon TCG API and records
/// a new `PriceSnapshot` so the trend charts stay up to date.
@MainActor
struct PriceRefreshService {
    let service: PokemonAPIService

    init(apiKey: String? = AppConfig.pokemonAPIKey) {
        self.service = PokemonAPIService(apiKey: apiKey)
    }

    /// Refresh a single card. Returns true if the price changed.
    @discardableResult
    func refresh(_ card: OwnedCard, context: ModelContext) async -> Bool {
        guard let price = try? await service.currentPrice(forCardId: card.apiCardId), price > 0 else {
            return false
        }
        let changed = abs(price - card.lastKnownPrice) > 0.001
        card.lastKnownPrice = price
        card.priceUpdatedAt = .now
        let snapshot = PriceSnapshot(price: price, date: .now)
        snapshot.card = card
        card.snapshots.append(snapshot)
        try? context.save()
        return changed
    }

    /// Refresh every owned card across all collections.
    func refreshAll(context: ModelContext) async {
        let descriptor = FetchDescriptor<OwnedCard>()
        guard let cards = try? context.fetch(descriptor) else { return }
        for card in cards {
            await refresh(card, context: context)
        }
    }
}
