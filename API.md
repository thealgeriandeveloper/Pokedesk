# Pokémon TCG API integration

Pokedesk gets card data and prices from the **[Pokémon TCG API v2](https://pokemontcg.io)**
(base URL `https://api.pokemontcg.io/v2`). It's free, returns official card images,
and aggregates marketplace prices.

All access is in [`Pokedesk/Services/PokemonAPIService.swift`](Pokedesk/Services/PokemonAPIService.swift).

---

## Authentication

A key is **optional**. Without one you use the anonymous quota; with one you get
higher rate limits. Set it in [`AppConfig.swift`](Pokedesk/App/AppConfig.swift):

```swift
static let pokemonAPIKey: String? = "your-key"
```

When present it's sent as the `X-Api-Key` header. Get a free key at
[dev.pokemontcg.io](https://dev.pokemontcg.io).

---

## Endpoints used

### 1. Search cards by name

```
GET /cards?q=name:"<query>*"&pageSize=20&orderBy=-set.releaseDate
```

Used by the add-card flow. Returns the newest matching cards first.

### 2. Single card (price refresh)

```
GET /cards/{id}
```

Used to re-fetch the latest market price for a card the user already owns.

---

## Pricing logic

The API exposes prices from two marketplaces. We pick the **best available** price
in this order (see `CardDTO.bestPrice`):

1. **TCGplayer** (USD): the max of each variant's `market` (fallback `mid`) price.
2. **Cardmarket** (EUR): `trendPrice`, fallback `averageSellPrice`.

```jsonc
{
  "data": {
    "id": "swsh9-154",
    "name": "Charizard V",
    "number": "154",
    "rarity": "Rare Holo V",
    "set": { "name": "Brilliant Stars" },
    "images": { "small": "...", "large": "..." },
    "tcgplayer": {
      "prices": {
        "holofoil": { "market": 12.34, "mid": 11.90 }
      }
    },
    "cardmarket": {
      "prices": { "trendPrice": 10.50, "averageSellPrice": 10.10 }
    }
  }
}
```

> **Note:** prices are not real-time. TCGplayer data typically updates about once
> per day, so treat values as "today's market price".

---

## Internal model

The decoder collapses the API response into a lightweight, view-ready struct:

```swift
struct APICard: Identifiable, Hashable {
    let id: String          // e.g. "swsh9-154"
    let name: String
    let setName: String
    let number: String
    let rarity: String
    let imageURLString: String?
    let marketPrice: Double? // best price across providers, or nil if unpriced
}
```

---

## Error handling

`PokemonAPIError` covers `invalidURL`, `requestFailed` (non-2xx), and `decoding`.
The search UI surfaces a friendly "Couldn't reach the card database." message and
falls back to an empty result set; price refresh fails silently (keeps the last
known price).

---

## Swapping the price source later

If you ever want live listings (e.g. eBay active listings), keep `OwnedCard.apiCardId`
as the canonical identity and add a new service that implements the same two calls
(`search` + `currentPrice`). Only `PokemonAPIService` and `PriceRefreshService`
would need to change — views and models are decoupled from the provider.
