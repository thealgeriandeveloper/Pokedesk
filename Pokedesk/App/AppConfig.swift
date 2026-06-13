import Foundation

/// App-wide configuration.
enum AppConfig {
    /// Optional Pokémon TCG API key. Leave nil to use the free anonymous quota,
    /// or paste a key from https://dev.pokemontcg.io for higher rate limits.
    static let pokemonAPIKey: String? = nil
}
