import Foundation
import FirebaseAuth

@MainActor
final class SubscriptionPostsViewModel: ObservableObject {

    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadSubscriptionPosts() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        PublicationService.shared.fetchPostsFromSubscriptions(for: userId) { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let posts):
                self.posts = posts
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
