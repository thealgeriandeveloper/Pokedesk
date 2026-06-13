import Foundation
import SwiftData

/// In-memory model container preloaded with sample data, for SwiftUI previews.
enum PreviewData {
    @MainActor static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: CardCollection.self, OwnedCard.self, PriceSnapshot.self, Expense.self,
            configurations: config
        )
        SampleData.seed(container.mainContext)
        return container
    }()

    @MainActor static var sampleCollection: CardCollection {
        let descriptor = FetchDescriptor<CardCollection>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? container.mainContext.fetch(descriptor).first) ?? CardCollection(name: "Demo")
    }

    @MainActor static var sampleCard: OwnedCard {
        sampleCollection.cards.first ?? OwnedCard(
            apiCardId: "demo", name: "Demo", setName: "Set", setNumber: "#1", rarity: "Basic"
        )
    }
}
