import SwiftUI
import SwiftData

/// Spending & profit overview: how much was spent on sealed/singles vs. current value.
struct SpendingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.purchaseDate, order: .reverse) private var expenses: [Expense]
    @Query private var collections: [CardCollection]

    @State private var filter: Filter = .all
    @State private var showAddExpense = false

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", booster = "Boosters", etb = "ETB", singles = "Singles"
        var id: String { rawValue }
        var matchingType: ExpenseType? {
            switch self {
            case .all: return nil
            case .booster: return .booster
            case .etb: return .etb
            case .singles: return .single
            }
        }
    }

    // MARK: - Totals (sealed expenses + cards in collections)

    private var cardsSpent: Double { collections.reduce(0) { $0 + $1.totalPaid } }
    private var cardsValue: Double { collections.reduce(0) { $0 + $1.totalValue } }
    private var expensesSpent: Double { expenses.reduce(0) { $0 + $1.totalPaid } }
    private var expensesValue: Double { expenses.reduce(0) { $0 + $1.totalEstimatedValue } }

    private var totalSpent: Double { cardsSpent + expensesSpent }
    private var currentValue: Double { cardsValue + expensesValue }
    private var profit: Double { currentValue - totalSpent }
    private var profitFraction: Double { totalSpent > 0 ? profit / totalSpent : 0 }

    private var filteredExpenses: [Expense] {
        guard let type = filter.matchingType else { return expenses }
        return expenses.filter { $0.type == type }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    summaryCard
                    filterChips
                    purchasesList
                }
                .padding(.horizontal, Theme.Spacing.margin)
                .padding(.vertical, Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Spending")
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Add expense", systemImage: "plus") { showAddExpense = true }
                    .padding(.horizontal, Theme.Spacing.margin)
                    .padding(.bottom, Theme.Spacing.xs)
            }
            .sheet(isPresented: $showAddExpense) {
                ExpenseFormView()
            }
        }
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total spent")
                    .font(Theme.Typography.labelSm)
                    .foregroundStyle(.white.opacity(0.9))
                Text(Money.string(totalSpent))
                    .font(Theme.Typography.displayLg)
                    .foregroundStyle(.white)
            }

            Divider().overlay(.white.opacity(0.3))

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current value")
                        .font(Theme.Typography.labelSm)
                        .foregroundStyle(.white.opacity(0.9))
                    Text(Money.string(currentValue))
                        .font(Theme.Typography.headlineMd)
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Profit")
                        .font(Theme.Typography.labelSm)
                        .foregroundStyle(.white.opacity(0.9))
                    profitBadge
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.amberGradient, in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .ctaShadow()
    }

    private var profitBadge: some View {
        let up = profit >= 0
        return HStack(spacing: 4) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
            Text("\(up ? "+" : "")\(Money.string(profit)) (\(String(format: "%.0f", profitFraction * 100))%)")
        }
        .font(.system(size: 13, weight: .bold, design: .rounded))
        .foregroundStyle(up ? Theme.Colors.positive : Theme.Colors.negative)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.white.opacity(0.92), in: Capsule())
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(Filter.allCases) { item in
                    ChipToggle(title: item.rawValue, isSelected: filter == item) { filter = item }
                }
            }
        }
    }

    private var purchasesList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Recent Purchases")
                .font(Theme.Typography.headlineSm)
                .foregroundStyle(Theme.Colors.onSurface)

            if filteredExpenses.isEmpty {
                Text("No purchases yet. Tap \u{201C}Add expense\u{201D} to log a booster, ETB or single.")
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .padding(.vertical, Theme.Spacing.md)
            } else {
                ForEach(filteredExpenses) { expense in
                    ExpenseRow(expense: expense)
                        .swipeActions {
                            Button(role: .destructive) {
                                context.delete(expense)
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                }
            }
        }
    }
}

/// A purchase row: type icon, name, date, amount paid and value delta.
private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: expense.type.systemImage)
                .font(.system(size: 18))
                .foregroundStyle(Theme.Colors.primaryDeep)
                .frame(width: 44, height: 44)
                .background(Theme.Colors.surfaceContainer, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(Theme.Typography.bodyLg)
                    .foregroundStyle(Theme.Colors.onSurface)
                    .lineLimit(1)
                Text(expense.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.Typography.labelSm)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.string(expense.totalPaid))
                    .font(Theme.Typography.priceMd)
                    .foregroundStyle(Theme.Colors.onSurface)
                if expense.estimatedValue > 0 {
                    let up = expense.changeFraction >= 0
                    Text("\(Money.string(expense.totalEstimatedValue)) (\(up ? "+" : "")\(String(format: "%.0f", expense.changeFraction * 100))%)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(up ? Theme.Colors.positive : Theme.Colors.negative)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .cardShadow()
    }
}

#Preview {
    SpendingView()
        .modelContainer(PreviewData.container)
}
