# Architecture

Pokedesk is a small **SwiftUI + SwiftData** app following a lightweight MVVM-ish structure:
views are thin, SwiftData models are the single source of truth, and computed
properties on the models derive values (totals, profit, deltas) so there's no
duplicated state to keep in sync.

```
┌─────────────┐     @Query / @Bindable      ┌──────────────┐
│   Views     │ ───────────────────────────▶│  SwiftData    │
│ (SwiftUI)   │◀─────────────────────────── │  (ModelContext)│
└─────────────┘     observes changes         └──────────────┘
       │                                            ▲
       │ async calls                                │ writes prices
       ▼                                            │
┌─────────────┐                            ┌──────────────────┐
│  Services    │ ──── Pokémon TCG API ────▶│ PriceRefreshService│
└─────────────┘                            └──────────────────┘
```

---

## Layers

### App (`Pokedesk/App/`)

| File | Role |
|------|------|
| `PokedeskApp.swift` | `@main` entry. Creates the `ModelContainer`, seeds demo data on first launch, injects the container into the environment. |
| `RootTabView.swift` | Bottom tab bar: **Explore** (Spending) and **Collection** (home). |
| `AppConfig.swift` | App-wide config. Holds the optional Pokémon TCG API key. |

### Design System (`Pokedesk/DesignSystem/`)

The visual language is derived from the Stitch `DESIGN.md` ("Collector's Sanctuary":
warm amber, off-white surfaces, hyper-rounded shapes, soft ambient shadows).

| File | Contents |
|------|----------|
| `Theme.swift` | `Theme.Colors`, `Theme.Typography`, `Theme.Spacing`, `Theme.Radius`, the `Color(hex:)` helper, and `cardShadow()` / `ctaShadow()` view modifiers. |
| `Components.swift` | Reusable UI: `MoneyLabel`, `CardThumbnail` (with quantity badge), `AmberProgressBar`, `PrimaryButton`, `AddCardsButton`, `ChipToggle`, `SearchField`, `QuantityStepper`, plus the `Money` currency formatter. |

**Design tokens** (from `DESIGN.md`):

- Primary amber `#F5A623`, gradient to `#FFC107` at 135°
- Background off-white `#FBF9F6`, white surfaces, container greys
- Positive green `#2E9E5B`, negative red `#D8443C`, dark quantity badge `#1A1A1A`
- Typeface intent: *Plus Jakarta Sans*; implemented with the system **rounded** design as a no-dependency fallback
- Card radius 16–20px, pill controls (100px)

### Models (`Pokedesk/Models/Models.swift`)

All persistence is SwiftData `@Model` classes. Money math lives in computed properties.

```
CardCollection
 ├─ id, name, detail, isDefault, createdAt
 ├─ cards: [OwnedCard]            (cascade delete)
 ├─ itemCount   = Σ quantity
 ├─ totalValue  = Σ (lastKnownPrice × quantity)
 ├─ totalPaid   = Σ (pricePaid × quantity)
 └─ valueDelta  = totalValue − totalPaid

OwnedCard
 ├─ id, apiCardId, name, setName, setNumber, rarity, imageURLString
 ├─ quantity, pricePaid           (what YOU paid, per card)
 ├─ lastKnownPrice, priceUpdatedAt (latest market price)
 ├─ collection: CardCollection?
 ├─ snapshots: [PriceSnapshot]    (cascade delete)
 ├─ currentValue    = lastKnownPrice × quantity
 ├─ totalPaid       = pricePaid × quantity
 └─ changeFraction  = (lastKnownPrice − pricePaid) / pricePaid

PriceSnapshot
 └─ id, price, date, card          (one point on the trend chart)

Expense        (sealed product or single purchase, for spend/profit)
 ├─ id, name, typeRaw, amountPaid, quantity, purchaseDate, estimatedValue
 ├─ type: ExpenseType  (booster / etb / single / other)  — wraps typeRaw
 ├─ totalPaid / totalEstimatedValue
 └─ changeFraction
```

> **Why store `apiCardId`?** It's the Pokémon TCG API id, used to re-fetch the
> current price during refresh without another search.

> **Why is profit computed, not stored?** Profit = `currentValue − totalSpent`,
> where `totalSpent` spans both cards (`OwnedCard.totalPaid`) and sealed products
> (`Expense.totalPaid`). Deriving it avoids stale data.

### Services (`Pokedesk/Services/`)

| File | Role |
|------|------|
| `PokemonAPIService.swift` | Async client for the Pokémon TCG API v2. `searchCards(matching:)` for the add-card flow; `currentPrice(forCardId:)` for refreshes. Decodes provider prices (TCGplayer `market`/`mid`, Cardmarket `trendPrice`/`averageSellPrice`) into a single best price. |
| `PriceRefreshService.swift` | `@MainActor` helper that refreshes one or all owned cards, updates `lastKnownPrice`, and appends a `PriceSnapshot`. Backs the pull-to-refresh. |
| `SampleData.swift` | Seeds demo collections, cards, price history and expenses on first launch (no-ops if data already exists). |
| `PreviewData.swift` | In-memory `ModelContainer` preloaded with sample data for SwiftUI previews. |

See [API.md](API.md) for the API request/response details.

### Features (`Pokedesk/Features/`)

Each screen is a folder. Views read data via `@Query` / `@Bindable` and write via
the injected `ModelContext` — no separate view-model objects were needed at this size.

| Feature | Files | Notes |
|---------|-------|-------|
| **Collections** | `CollectionsHomeView`, `CollectionDetailView`, `CollectionFormView` | Home list, set-grouped detail with progress + value, create/edit form (the form is reused for both via an optional `editing:` parameter). |
| **AddCard** | `CardSearchView`, `AddToCollectionSheet` | Debounced live search against the API; a sheet to confirm quantity + price paid before saving. |
| **CardDetail** | `CardDetailView` | Hero artwork, live value, Trends (Swift Charts) / Details / Listings tabs, refresh button. |
| **Spending** | `SpendingView`, `ExpenseFormView` | Profit dashboard with category filters; add-expense form. |

---

## Data flow examples

**Adding a card**
1. `CardSearchView` debounces the query → `PokemonAPIService.searchCards`.
2. Tapping a result opens `AddToCollectionSheet`.
3. On save: a new `OwnedCard` is inserted, linked to the `CardCollection`, with an
   initial `PriceSnapshot`. SwiftData publishes the change → the collection's
   `@Query`-driven views update automatically.

**Refreshing prices**
1. Pull-to-refresh on the home screen calls `PriceRefreshService.refreshAll`.
2. For each `OwnedCard`, it fetches the latest price, updates `lastKnownPrice`,
   and appends a `PriceSnapshot` (feeding the trend chart).

**Profit calculation**
- `SpendingView` sums `totalPaid` and `totalValue` across all collections **and**
  all expenses → `profit = currentValue − totalSpent`.

---

## Conventions

- **No force-unwraps** in feature code; optional prices fall back gracefully.
- **Money formatting** goes through `Money.string(_:)` — never hand-format currency.
- **Colors / fonts / spacing** come only from `Theme.*` — don't hardcode hex or sizes in views.
- **New files** are picked up automatically: the Xcode project uses a
  *file-system-synchronized group*, so dropping a `.swift` file into `Pokedesk/`
  adds it to the target without editing `project.pbxproj`.

---

## Known limitations

- Prices reflect the API's update cadence (~daily for TCGplayer), not real-time.
- Marketplace "Listings" are illustrative (derived from the market price), not live seller data.
- No authentication or multi-device sync yet (see [ROADMAP.md](ROADMAP.md)).
