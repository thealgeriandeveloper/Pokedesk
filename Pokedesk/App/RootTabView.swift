import SwiftUI

/// Bottom tab navigation: Explore (spending overview) and Collection.
struct RootTabView: View {
    @State private var selection: Tab = .collection

    enum Tab { case explore, collection }

    var body: some View {
        TabView(selection: $selection) {
            SpendingView()
                .tabItem {
                    Label("Explore", systemImage: selection == .explore ? "safari.fill" : "safari")
                }
                .tag(Tab.explore)

            CollectionsHomeView()
                .tabItem {
                    Label("Collection", systemImage: selection == .collection ? "rectangle.stack.fill" : "rectangle.stack")
                }
                .tag(Tab.collection)
        }
        .tint(Theme.Colors.primaryDeep)
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
}
