import SwiftUI
import SwiftData

/// Search the Pokémon TCG API by name and add a result to a collection.
struct CardSearchView: View {
    let collection: CardCollection

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [APICard] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selected: APICard?
    @State private var searchTask: Task<Void, Never>?

    private let service = PokemonAPIService(apiKey: AppConfig.pokemonAPIKey)

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                SearchField(placeholder: "Search any card…", text: $query)
                    .padding(.horizontal, Theme.Spacing.margin)
                    .padding(.top, Theme.Spacing.sm)
                    .onChange(of: query) { _, newValue in scheduleSearch(newValue) }

                content
            }
            .background(Theme.Colors.background)
            .navigationTitle("Add card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.primaryDeep)
                }
            }
            .sheet(item: $selected) { card in
                AddToCollectionSheet(apiCard: card, collection: collection) { dismiss() }
                    .presentationDetents([.medium, .large])
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            Spacer()
            ProgressView().tint(Theme.Colors.primary)
            Spacer()
        } else if let errorMessage {
            Spacer()
            ContentUnavailableView("Search failed", systemImage: "wifi.slash", description: Text(errorMessage))
            Spacer()
        } else if results.isEmpty {
            Spacer()
            ContentUnavailableView(
                query.isEmpty ? "Search for a card" : "No results",
                systemImage: "magnifyingglass",
                description: Text(query.isEmpty ? "Type a card name to find its market price." : "Try a different name.")
            )
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(results) { card in
                        Button { selected = card } label: { resultRow(card) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.margin)
            }
        }
    }

    private func resultRow(_ card: APICard) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            CardThumbnail(imageURL: card.imageURL, quantity: 1, width: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(Theme.Typography.bodyLg)
                    .foregroundStyle(Theme.Colors.onSurface)
                Text("\(card.setName)  ·  #\(card.number)")
                    .font(Theme.Typography.labelSm)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            if let price = card.marketPrice {
                Text(Money.string(price))
                    .font(Theme.Typography.priceMd)
                    .foregroundStyle(Theme.Colors.onSurface)
            } else {
                Text("—").foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .cardShadow()
    }

    /// Debounced search: wait briefly after the last keystroke before querying.
    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            results = []
            errorMessage = nil
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await runSearch(trimmed)
        }
    }

    private func runSearch(_ text: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let found = try await service.searchCards(matching: text)
            guard !Task.isCancelled else { return }
            results = found
        } catch {
            errorMessage = "Couldn't reach the card database."
            results = []
        }
    }
}

#Preview {
    CardSearchView(collection: PreviewData.sampleCollection)
        .modelContainer(PreviewData.container)
}
