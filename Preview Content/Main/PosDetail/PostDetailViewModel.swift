import SwiftUI
import FirebaseAuth

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var post: Post?
    private let currentUserId = Auth.auth().currentUser?.uid ?? ""

    func loadPost(with id: String) async {
        do {
            self.post = try await PublicationService.shared.fetchPostById(postId: id)
        } catch {
            print("Error loading post: \(error.localizedDescription)")
        }
    }

    func toggleLike() {
        guard let post = post, !currentUserId.isEmpty else { return }

        var updatedLiked = post.likedBy ?? []
        var updatedPost = post

        if updatedLiked.contains(currentUserId) {
            updatedLiked.removeAll { $0 == currentUserId }
            updatedPost.likesCount = max(0, updatedPost.likesCount - 1)
        } else {
            updatedLiked.append(currentUserId)
            updatedPost.likesCount += 1
        }

        updatedPost.likedBy = updatedLiked
        self.post = updatedPost
        save(post: updatedPost)
    }

    var isLikedByCurrentUser: Bool {
        guard let post = post else { return false }
        return post.likedBy?.contains(currentUserId) ?? false
    }

    private func save(post: Post) {
        PublicationService.shared.uploadPost(post, completion: {_ in })
    }
}
