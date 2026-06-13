import SwiftUI
import SwiftData

/// Create a new collection, or edit an existing one when `editing` is provided.
struct CollectionFormView: View {
    /// Pass an existing collection to edit it; nil creates a new one.
    var editing: CardCollection? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var detail = ""
    @State private var isDefault = false

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                field(title: "Name") {
                    TextField("First sets", text: $name)
                        .textFieldStyle(.plain)
                        .font(Theme.Typography.bodyLg)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.Colors.surfaceContainer, lineWidth: 1))
                }

                field(title: "Description (optional)") {
                    TextField("Dream collection? Or your entire deck?", text: $detail, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .font(Theme.Typography.bodyLg)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.Colors.surfaceContainer, lineWidth: 1))
                }

                Toggle(isOn: $isDefault) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default collection")
                            .font(Theme.Typography.bodyLg)
                            .foregroundStyle(Theme.Colors.onSurface)
                        Text("Make this collection a default?")
                            .font(Theme.Typography.labelSm)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                .tint(Theme.Colors.primary)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surfaceLow, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))

                Spacer()

                PrimaryButton(title: "Save", systemImage: "checkmark") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
            .padding(Theme.Spacing.margin)
            .background(Theme.Colors.background)
            .navigationTitle(isEditing ? "Edit collection" : "New collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .onAppear {
                if let editing {
                    name = editing.name
                    detail = editing.detail
                    isDefault = editing.isDefault
                }
            }
        }
    }

    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.labelSm)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            content()
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespaces)
        if let editing {
            editing.name = trimmedName
            editing.detail = trimmedDetail
            editing.isDefault = isDefault
        } else {
            let collection = CardCollection(name: trimmedName, detail: trimmedDetail, isDefault: isDefault)
            context.insert(collection)
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    CollectionFormView()
        .modelContainer(PreviewData.container)
}
