import SwiftUI

struct TabBarItemView: View {
    let tab: TabBarViewModel.Tab
    @Binding var selectedTab: TabBarViewModel.Tab

    private var iconName: String {
        switch tab {
        case .home:
            return "magnifyingglass"
        case .create:
            return "plus"
        case .profile:
            return "person.fill"
        case .recomended:
            return "house.fill"
        }
    }

    var body: some View {
        Button(action: {
            selectedTab = tab
        }) {
            Image(systemName: iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
                .foregroundColor(selectedTab == tab ? .white : Color("primaryColor"))
                .padding(16)
                .background(selectedTab == tab ? Color("primaryColor") : Color("BackgroundColor"))
                .cornerRadius(45)
        }
    }
}

#Preview {
    TabBarItemView(tab: .create, selectedTab: .constant(.create))
}
