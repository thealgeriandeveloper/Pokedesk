import SwiftUI
import SwiftData

@main
struct PokedeskApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: CardCollection.self, OwnedCard.self, PriceSnapshot.self, Expense.self
            )
            SampleData.seedIfNeeded(container.mainContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
