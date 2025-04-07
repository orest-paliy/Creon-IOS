import SwiftUI

class TabBarViewModel: ObservableObject {
    enum Tab {
        case home, create, profile, recomended
    }

    @Published var selectedTab: Tab = .recomended
}
