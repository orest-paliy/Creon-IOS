import SwiftUI
import FirebaseDatabase
import FirebaseAuth

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var post: Post
    @Published var newCommentText: String = ""
    @Published var comments: [Comment] = []
    @Published var errorMessage: String?

    private let database = Database.database().reference()
    private let currentUserId = Auth.auth().currentUser?.uid ?? ""

    init(post: Post) {
        self.post = post
        self.comments = post.comments ?? []
    }

    func addComment() async {
        guard !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Коментар не може бути порожнім."
            return
        }

        guard !currentUserId.isEmpty else { return }

        let newComment = Comment(
            id: UUID().uuidString,
            userId: currentUserId,
            text: newCommentText,
            createdAt: Date()
        )

        comments.append(newComment)
        post.comments = comments
        newCommentText = ""

        do {
            let commentsData = try comments.map { try JSONEncoder().encode($0) }
            let commentsDict = commentsData.compactMap { try? JSONSerialization.jsonObject(with: $0) }

            try await database.child("posts/\(post.id)/comments").setValue(commentsDict)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleLike() {
        guard !currentUserId.isEmpty else { return }

        var liked = post.likedBy ?? []

        if liked.contains(currentUserId) {
            liked.removeAll { $0 == currentUserId }
            post.likesCount = max(0, post.likesCount - 1)
        } else {
            liked.append(currentUserId)
            post.likesCount += 1
        }

        post.likedBy = liked

        savePostToFirebase()
    }

    private func savePostToFirebase() {
        let ref = database.child("posts").child(post.id)

        do {
            let data = try JSONEncoder().encode(post)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            ref.setValue(dict)
        } catch {
            print("❌ Помилка при збереженні поста: \(error.localizedDescription)")
        }
    }

    var isLikedByCurrentUser: Bool {
        post.likedBy?.contains(currentUserId) ?? false
    }
    
    func fetchPostFromFirebase() {
        let ref = Database.database().reference().child("posts").child(post.id)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard
                let dict = snapshot.value as? [String: Any],
                let data = try? JSONSerialization.data(withJSONObject: dict),
                let updatedPost = try? JSONDecoder().decode(Post.self, from: data)
            else {
                return
            }

            self.post = updatedPost
        }
    }

}
