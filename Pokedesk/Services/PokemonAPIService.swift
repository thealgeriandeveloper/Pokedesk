import Foundation

/// A lightweight, view-ready representation of a card returned by the Pokémon TCG API.
struct APICard: Identifiable, Hashable {
    let id: String
    let name: String
    let setName: String
    let number: String
    let rarity: String
    let imageURLString: String?
    /// Best available market price in USD, or nil if unpriced.
    let marketPrice: Double?

    var imageURL: URL? { imageURLString.flatMap(URL.init(string:)) }
}

enum PokemonAPIError: Error {
    case invalidURL
    case requestFailed
    case decoding
}

/// Talks to the free Pokémon TCG API (https://pokemontcg.io).
///
/// An API key is optional but recommended (higher rate limits). Set it via
/// `PokemonAPIService(apiKey:)`. Without a key you still get a usable quota.
struct PokemonAPIService {
    let apiKey: String?
    private let session: URLSession
    private let baseURL = URL(string: "https://api.pokemontcg.io/v2")!

    init(apiKey: String? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Search cards by name. Returns up to `pageSize` priced results.
    func searchCards(matching query: String, pageSize: Int = 20) async throws -> [APICard] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(url: baseURL.appendingPathComponent("cards"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "q", value: "name:\"\(trimmed)*\""),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "orderBy", value: "-set.releaseDate")
        ]
        guard let url = components?.url else { throw PokemonAPIError.invalidURL }

        var request = URLRequest(url: url)
        if let apiKey { request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key") }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw PokemonAPIError.requestFailed
        }
        do {
            let decoded = try JSONDecoder().decode(CardListResponse.self, from: data)
            return decoded.data.map(\.asAPICard)
        } catch {
            throw PokemonAPIError.decoding
        }
    }

    /// Fetch the latest market price for a single card id (used to refresh values).
    func currentPrice(forCardId id: String) async throws -> Double? {
        let url = baseURL.appendingPathComponent("cards/\(id)")
        var request = URLRequest(url: url)
        if let apiKey { request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key") }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw PokemonAPIError.requestFailed
        }
        let decoded = try JSONDecoder().decode(SingleCardResponse.self, from: data)
        return decoded.data.asAPICard.marketPrice
    }
}

// MARK: - Decoding

private struct CardListResponse: Decodable {
    let data: [CardDTO]
}

private struct SingleCardResponse: Decodable {
    let data: CardDTO
}

private struct CardDTO: Decodable {
    let id: String
    let name: String
    let number: String?
    let rarity: String?
    let set: SetDTO?
    let images: ImagesDTO?
    let tcgplayer: TCGPlayerDTO?
    let cardmarket: CardmarketDTO?

    struct SetDTO: Decodable { let name: String? }
    struct ImagesDTO: Decodable { let small: String?; let large: String? }

    struct TCGPlayerDTO: Decodable {
        let prices: [String: PriceBucket]?
        struct PriceBucket: Decodable { let market: Double?; let mid: Double? }
    }
    struct CardmarketDTO: Decodable {
        let prices: CMPrices?
        struct CMPrices: Decodable { let averageSellPrice: Double?; let trendPrice: Double? }
    }

    /// Pick the best available market price across providers.
    private var bestPrice: Double? {
        if let buckets = tcgplayer?.prices?.values {
            let markets = buckets.compactMap { $0.market ?? $0.mid }
            if let max = markets.max() { return max }
        }
        if let cm = cardmarket?.prices {
            return cm.trendPrice ?? cm.averageSellPrice
        }
        return nil
    }

    var asAPICard: APICard {
        APICard(
            id: id,
            name: name,
            setName: set?.name ?? "Unknown set",
            number: number ?? "",
            rarity: rarity ?? "Unknown",
            imageURLString: images?.large ?? images?.small,
            marketPrice: bestPrice
        )
    }
}
