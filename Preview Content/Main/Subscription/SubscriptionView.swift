import SwiftUI

struct SubscriptionPostsView: View {
    @StateObject private var viewModel = SubscriptionPostsViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.posts, id: \.id) { post in
                    PostRowView(posts: $viewModel.posts, post: post, isThisYourProfile: false)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }

                if let error = viewModel.errorMessage {
                    Text("Помилка: \(error)")
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Публікації")
        .onAppear {
            viewModel.loadSubscriptionPosts()
        }
    }
}
