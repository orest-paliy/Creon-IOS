import SwiftUI

class TabBarViewModel: ObservableObject {
    enum Tab {
        case home, create, profile
    }

    @Published var selectedTab: Tab = .home
}
