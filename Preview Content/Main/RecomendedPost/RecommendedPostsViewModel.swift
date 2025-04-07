import Foundation
import FirebaseAuth

@MainActor
final class RecommendedPostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false

    func loadRecommendedPosts(limit: Int = 10) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await UserProfileService.shared.fetchUserProfile(uid: userId)
            let embedding = user.embedding ?? []
            let posts = try await PublicationService.shared.fetchRecommendedPosts(userEmbedding: embedding)
            self.posts = posts
        } catch {
            print("❌ Не вдалося завантажити рекомендовані пости:", error.localizedDescription)
        }
    }
}
