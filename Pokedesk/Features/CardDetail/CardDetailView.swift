import SwiftUI
import SwiftData
import Charts

/// Card detail: hero artwork on an amber gradient, live market value, and a
/// Trends / Details / Listings segmented section.
struct CardDetailView: View {
    @Bindable var card: OwnedCard
    @Environment(\.modelContext) private var context

    @State private var tab: DetailTab = .trends
    @State private var range: ChartRange = .sixMonths
    @State private var isRefreshing = false
    @State private var pickerSelection: Set<CardCollection> = []
    @State private var activeSheet: ActiveSheet?
    @State private var showDeleteConfirm = false

    /// Single source of truth for which sheet is presented.
    private enum ActiveSheet: Identifiable {
        case picker, edit
        var id: Int { hashValue }
    }
    @Environment(\.dismiss) private var dismiss

    enum DetailTab: String, CaseIterable { case trends = "Trends", details = "Details", listings = "Listings" }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                hero
                valueSummary
                segmentedTabs

                switch tab {
                case .trends: TrendsSection(card: card, range: $range)
                case .details: DetailsSection(card: card)
                case .listings: ListingsSection(card: card)
                }
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await refreshPrice() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .symbolEffect(.pulse, isActive: isRefreshing)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { activeSheet = .edit } label: { Label("Edit card", systemImage: "pencil") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Remove card", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(item: $activeSheet, onDismiss: handleSheetDismiss) { sheet in
            switch sheet {
            case .picker:
                NavigationStack { CollectionPickerView(selection: $pickerSelection) }
            case .edit:
                EditCardSheet(card: card)
            }
        }
        .alert("Remove \u{201C}\(card.name)\u{201D}?", isPresented: $showDeleteConfirm) {
            Button("Remove", role: .destructive) {
                context.delete(card)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the card from this collection. This can't be undone.")
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: Theme.Spacing.md) {
            CardThumbnail(imageURL: card.imageURL, quantity: 1, width: 200)
                .cardShadow()
                .padding(.top, Theme.Spacing.md)

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(card.name)
                        .font(Theme.Typography.headlineMd)
                        .foregroundStyle(Theme.Colors.onSurface)
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.Colors.primary)
                }
                Text("\(card.rarity)  ·  \(card.setNumber) \(card.setName)")
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Theme.Spacing.lg)
        .background(Theme.Colors.amberGradient.opacity(0.25))
    }

    // MARK: - Value summary

    private var valueSummary: some View {
        VStack(spacing: 4) {
            Text("Avg market price")
                .font(Theme.Typography.labelSm)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(Money.string(card.lastKnownPrice))
                .font(Theme.Typography.displayLg)
                .foregroundStyle(Theme.Colors.onSurface)
            HStack(spacing: 4) {
                Image(systemName: card.changeFraction >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text(percent(card.changeFraction))
                Text("vs. paid").foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .font(Theme.Typography.labelSm)
            .foregroundStyle(card.changeFraction >= 0 ? Theme.Colors.positive : Theme.Colors.negative)

            Text("Live price · updated \(card.priceUpdatedAt.formatted(.relative(presentation: .named)))")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var segmentedTabs: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { tab = item }
                } label: {
                    Text(item.rawValue)
                        .font(Theme.Typography.labelSm)
                        .foregroundStyle(tab == item ? .white : Theme.Colors.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if tab == item { Capsule().fill(Theme.Colors.amberGradient) }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.Colors.surfaceContainer, in: Capsule())
        .padding(.horizontal, Theme.Spacing.margin)
    }

    // MARK: - Bottom bar (quantity + save)

    private var bottomBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            QuantityStepper(value: $card.quantity)
                .onChange(of: card.quantity) { _, _ in try? context.save() }
            PrimaryButton(title: "Add to collections", systemImage: "plus.circle.fill") {
                pickerSelection = Set([card.collection].compactMap { $0 })
                activeSheet = .picker
            }
        }
        .padding(.horizontal, Theme.Spacing.margin)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    /// Runs when any sheet is dismissed. The picker's changes are applied here;
    /// `pickerSelection` is empty after edit/other sheets, so it's a safe no-op.
    private func handleSheetDismiss() {
        applyCollectionChanges()
    }

    /// After picking, add a copy of this card to any newly selected collection
    /// that doesn't already contain it.
    private func applyCollectionChanges() {
        for target in pickerSelection {
            let alreadyThere = target.cards.contains { $0.apiCardId == card.apiCardId }
            guard !alreadyThere else { continue }
            let copy = OwnedCard(
                apiCardId: card.apiCardId,
                name: card.name,
                setName: card.setName,
                setNumber: card.setNumber,
                rarity: card.rarity,
                imageURLString: card.imageURLString,
                quantity: card.quantity,
                pricePaid: card.pricePaid,
                lastKnownPrice: card.lastKnownPrice
            )
            copy.collection = target
            target.cards.append(copy)
            let snapshot = PriceSnapshot(price: copy.lastKnownPrice, date: .now)
            snapshot.card = copy
            copy.snapshots.append(snapshot)
            context.insert(copy)
        }
        try? context.save()
        // Clear so a later non-picker sheet dismissal doesn't re-add copies.
        pickerSelection = []
    }

    // MARK: - Actions

    private func refreshPrice() async {
        isRefreshing = true
        defer { isRefreshing = false }
        let service = PokemonAPIService(apiKey: AppConfig.pokemonAPIKey)
        if let price = try? await service.currentPrice(forCardId: card.apiCardId), price > 0 {
            card.lastKnownPrice = price
            card.priceUpdatedAt = .now
            let snapshot = PriceSnapshot(price: price, date: .now)
            snapshot.card = card
            card.snapshots.append(snapshot)
            try? context.save()
        }
    }

    private func percent(_ fraction: Double) -> String {
        let sign = fraction >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", fraction * 100))%"
    }
}

// MARK: - Trends

private enum ChartRange: String, CaseIterable, Identifiable {
    case week = "7D", month = "1M", quarter = "3M", sixMonths = "6M"
    var id: String { rawValue }
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .sixMonths: return 180
        }
    }
}

private struct TrendsSection: View {
    let card: OwnedCard
    @Binding var range: ChartRange

    private var points: [PriceSnapshot] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: .now) ?? .distantPast
        return card.snapshots.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(ChartRange.allCases) { item in
                    ChipToggle(title: item.rawValue, isSelected: range == item) { range = item }
                }
            }

            Chart(points) { point in
                AreaMark(x: .value("Date", point.date), y: .value("Price", point.price))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(
                        colors: [Theme.Colors.positive.opacity(0.25), .clear],
                        startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Date", point.date), y: .value("Price", point.price))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.Colors.positive)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 200)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .cardShadow()
        }
        .padding(.horizontal, Theme.Spacing.margin)
    }
}

// MARK: - Details

private struct DetailsSection: View {
    let card: OwnedCard

    var body: some View {
        VStack(spacing: 0) {
            detailRow("Set", card.setName)
            Divider()
            detailRow("Number", card.setNumber)
            Divider()
            detailRow("Rarity", card.rarity)
            Divider()
            detailRow("Quantity owned", "\(card.quantity)")
            Divider()
            detailRow("Price paid (each)", Money.string(card.pricePaid))
            Divider()
            detailRow("Total paid", Money.string(card.totalPaid))
            Divider()
            detailRow("Current value", Money.string(card.currentValue))
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .cardShadow()
        .padding(.horizontal, Theme.Spacing.margin)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Text(value)
                .font(Theme.Typography.bodyLg)
                .foregroundStyle(Theme.Colors.onSurface)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Listings (placeholder marketplace rows)

private struct ListingsSection: View {
    let card: OwnedCard

    private var listings: [(seller: String, price: Double)] {
        [("Shopee", card.lastKnownPrice),
         ("Tokopaedi", card.lastKnownPrice * 0.86),
         ("eBay", card.lastKnownPrice * 1.05)]
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(listings, id: \.seller) { listing in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(listing.seller)
                            .font(Theme.Typography.bodyLg)
                            .foregroundStyle(Theme.Colors.onSurface)
                        Text("100% (43 sales)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    Spacer()
                    MoneyLabel(amount: listing.price)
                    Button {} label: {
                        Text("Buy now")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Theme.Colors.amberGradient, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                .cardShadow()
            }
        }
        .padding(.horizontal, Theme.Spacing.margin)
    }
}

#Preview {
    NavigationStack {
        CardDetailView(card: PreviewData.sampleCard)
    }
    .modelContainer(PreviewData.container)
}
