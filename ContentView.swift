import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var viewModel = TabBarViewModel()
    @State private var showCreatePost = false
    @State private var selectedPost: Post?
    
    @State private var isUserLoggedIn = Auth.auth().currentUser != nil
    
    var body: some View {
        Group {
            if isUserLoggedIn {
                mainAppView
            } else {
                AuthView()
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, user in
                withAnimation {
                    isUserLoggedIn = user != nil
                }
            }
        }
    }
    
    private var mainAppView: some View {
        NavigationStack {
            ZStack {
                ZStack {
                    switch viewModel.selectedTab {
                    case .home:
                        HomeView(selectedPost: $selectedPost)
                    case .profile:
                        ProfileView(onLogout: {
                            try? Auth.auth().signOut()
                        }, selectedPost: $selectedPost)
                    case .create:
                        EmptyView()
                    }
                }
                VStack{
                    Spacer()
                    TabBarView(selectedTab: $viewModel.selectedTab)
                }
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .fullScreenCover(isPresented: $showCreatePost) {
                if let uid = Auth.auth().currentUser?.uid {
                    CreatePostView(authorId: uid, didFinishPosting: .constant(false), selectedTab: $viewModel.selectedTab)
                } else {
                    Text("Будь ласка, увійдіть у систему")
                }
            }
            .background(Color("BackgroundColor"))
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: .constant(post))
            }
            .onChange(of: viewModel.selectedTab){
                if $0 == .create {
                    showCreatePost = true
                }
            }
        }
    }
}
