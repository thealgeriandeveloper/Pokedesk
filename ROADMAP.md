# Roadmap

Status of the Pokedesk build. Done items are shipped and verified in the simulator.

## ✅ Done

- [x] Xcode project (SwiftUI + SwiftData, iOS 17+, file-system-synchronized group)
- [x] Design system from `DESIGN.md` (colors, typography, spacing, reusable components)
- [x] SwiftData models: `CardCollection`, `OwnedCard`, `PriceSnapshot`, `Expense`
- [x] Pokémon TCG API client + demo data seeding
- [x] **Collections home** — list with value, quantity badges, previews
- [x] **Collection detail** — set-grouped, search, progress + value summary
- [x] **Card detail** — live value, trend chart (Swift Charts), details, listings
- [x] **Add card** — debounced API search + "Add to collection" sheet
- [x] **Spending & profit** — dashboard + add-expense form
- [x] Create / **edit** / **delete** collections
- [x] **Pull-to-refresh** prices across all cards
- [x] **"Pick collections"** — add one card to multiple collections at once (checkboxes + create-new)
- [x] **Active "Add to collections"** from card detail (copies the card into newly picked collections)
- [x] **Edit quantity** of an owned card live from the detail screen (stepper, auto-saved)
- [x] **Edit price paid / remove** an owned card (… menu + edit sheet) from the detail screen
- [x] **App icon** (amber gradient + card with value trend line)
- [x] **Scan a card by photo** — camera + on-device Vision OCR → API match, with confirm / choose-result / no-match screens (does not store the personal photo)

## 🔜 Next
- [ ] Per-card "revenue today" indicator using the latest two snapshots
- [ ] Tune OCR matching heuristics on real photos (name guess, confidence thresholds)

## 💡 Later / nice-to-have

- [ ] iCloud sync via CloudKit (multi-device)
- [ ] Real marketplace listings (eBay active listings) behind a provider abstraction
- [ ] Export / import collection (CSV or JSON)
- [ ] Filters on the search & listings screens
- [ ] Widgets (total portfolio value on the home screen)
- [ ] Unit tests for money/profit math; snapshot tests for key screens

## Design references

The original Google Stitch mockups and the design system spec live in
[`stitch_pokedesk_card_value_tracker/`](stitch_pokedesk_card_value_tracker/)
(`DESIGN.md` + per-screen `screen.png` / `code.html`).
