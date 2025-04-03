import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: TabBarViewModel.Tab

    var body: some View {
        HStack {
            Spacer()
            TabBarItemView(tab: .home, selectedTab: $selectedTab)
            Spacer()
            TabBarItemView(tab: .create, selectedTab: $selectedTab)
            Spacer()
            TabBarItemView(tab: .profile, selectedTab: $selectedTab)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.container)
        .padding(.vertical, 10)
        .padding(.bottom)
        .background(.ultraThinMaterial)
        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
    }
}

#Preview {
    TabBarView(selectedTab: .constant(.create))
}
