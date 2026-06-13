import SwiftUI
import SwiftData

/// Log a new purchase (booster / ETB / single / other).
struct ExpenseFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var type: ExpenseType = .booster
    @State private var amountText = ""
    @State private var estimatedText = ""
    @State private var purchaseDate = Date()
    @State private var quantity = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    field("Product Name") {
                        TextField("e.g. 151 Elite Trainer Box", text: $name)
                            .modifier(InputBox())
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Type")
                            .font(Theme.Typography.labelSm)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        FlowChips(selection: $type)
                    }

                    HStack(spacing: Theme.Spacing.md) {
                        field("Amount Paid (each)") {
                            HStack {
                                Text("$").foregroundStyle(Theme.Colors.secondaryLabel)
                                TextField("0.00", text: $amountText)
                                    .keyboardType(.decimalPad)
                            }
                            .modifier(InputBox())
                        }
                        field("Current Value (each)") {
                            HStack {
                                Text("$").foregroundStyle(Theme.Colors.secondaryLabel)
                                TextField("0.00", text: $estimatedText)
                                    .keyboardType(.decimalPad)
                            }
                            .modifier(InputBox())
                        }
                    }

                    field("Purchase Date") {
                        DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                            .labelsHidden()
                            .modifier(InputBox())
                    }

                    HStack {
                        Text("Quantity")
                            .font(Theme.Typography.bodyLg)
                            .foregroundStyle(Theme.Colors.onSurface)
                        Spacer()
                        QuantityStepper(value: $quantity)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                    .cardShadow()
                }
                .padding(Theme.Spacing.margin)
            }
            .background(Theme.Colors.background)
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Save expense", systemImage: "checkmark") { save() }
                    .padding(.horizontal, Theme.Spacing.margin)
                    .padding(.bottom, Theme.Spacing.xs)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.labelSm)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            content()
        }
    }

    private func save() {
        let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let estimated = Double(estimatedText.replacingOccurrences(of: ",", with: ".")) ?? amount
        let expense = Expense(
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            amountPaid: amount,
            quantity: quantity,
            purchaseDate: purchaseDate,
            estimatedValue: estimated
        )
        context.insert(expense)
        try? context.save()
        dismiss()
    }
}

/// Wrapping row of selectable type chips.
private struct FlowChips: View {
    @Binding var selection: ExpenseType

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 90), spacing: Theme.Spacing.xs)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(ExpenseType.allCases) { item in
                ChipToggle(title: item.rawValue, isSelected: selection == item) { selection = item }
            }
        }
    }
}

/// Shared input-box styling for form fields.
private struct InputBox: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Typography.bodyLg)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.Colors.surfaceContainer, lineWidth: 1))
    }
}

#Preview {
    ExpenseFormView()
        .modelContainer(PreviewData.container)
}
