# Contributing

Thanks for your interest in Pokedesk! This is a small, focused iOS app — these
notes keep things consistent.

## Getting set up

1. Xcode 16+ (developed on 26.5), iOS 17+ simulator.
2. `open Pokedesk.xcodeproj`, then **⌘R**.
3. No package manager needed — Apple frameworks only.

## Project conventions

- **Design tokens only.** Use `Theme.Colors`, `Theme.Typography`, `Theme.Spacing`,
  `Theme.Radius`. Don't hardcode hex colors, font sizes, or paddings in views.
- **Reuse components.** Check `DesignSystem/Components.swift` before building new UI
  (buttons, chips, thumbnails, money labels, steppers already exist).
- **Money** is always formatted through `Money.string(_:)`.
- **Models own the math.** Totals, deltas and profit are computed properties on the
  SwiftData models — add new derived values there, not in views.
- **Provider isolation.** Anything touching the price API goes through
  `PokemonAPIService` / `PriceRefreshService`. Views and models stay provider-agnostic.
- **Adding files** is automatic: the target uses a file-system-synchronized group,
  so new `.swift` files under `Pokedesk/` are included without touching the project file.

## Style

- Swift API Design Guidelines; clear names over comments.
- Prefer `async/await` for async work; keep UI-touching code on `@MainActor`.
- Avoid force-unwraps in feature code; degrade gracefully when prices are missing.

## Commits & PRs

- Small, focused commits with descriptive messages.
- One feature/fix per PR; describe what changed and why.
- If a change is visible, attach a simulator screenshot.

## Before opening a PR

```bash
xcodebuild -project Pokedesk.xcodeproj -scheme Pokedesk \
  -destination 'generic/platform=iOS Simulator' build
```

Make sure the build succeeds and the app launches without console errors.

## Roadmap

Open to ideas from [ROADMAP.md](ROADMAP.md). Feel free to pick an unchecked item.
