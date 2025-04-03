import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct CommentsView: View {
    @Environment(\.dismiss) private var dismiss

    var post: Post

    @State private var comments: [Comment] = []
    @State private var newComment: String = ""
    @State private var errorMessage: String?

    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""

    private let database = Database.database().reference()

    var body: some View {
        VStack(spacing: 0) {
            header

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(comments) { comment in
                        CommentRowView(
                            comment: comment,
                            onLikeTapped: { Task { await toggleLike(for: comment.id) } },
                            isLiked: comment.likedBy?.contains(currentUserId) ?? false
                        )
                        .padding(.horizontal)
                    }
                }
            }

            Divider()

            inputField
        }
        .background(Color.white)
        .onAppear {
            Task { await fetchComments() }
        }
    }

    private var header: some View {
        VStack{
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                
                Text("Коментарі")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal)
            
            Divider()
        }
    }

    private var inputField: some View {
        HStack {
            TextField("Ваш коментар...", text: $newComment)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(20)

            Button {
                Task { await addComment() }
            } label: {
                Image(systemName: "paperplane")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.purple)
                    .clipShape(Circle())
            }
            .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
        .background(Color.white)
    }

    private func fetchComments() async {
        let ref = database.child("posts/\(post.id)/comments")

        do {
            let snapshot = try await ref.getDataAsync()
            var fetched: [Comment] = []

            let sortedChildren = snapshot.children
                .compactMap { $0 as? DataSnapshot }
                .sorted { Int($0.key) ?? 0 < Int($1.key) ?? 0 }

            for snap in sortedChildren {
                guard
                    let dict = snap.value as? [String: Any],
                    let data = try? JSONSerialization.data(withJSONObject: dict),
                    let comment = try? JSONDecoder().decode(Comment.self, from: data)
                else { continue }

                fetched.append(comment)
            }

            self.comments = fetched.sorted {
                ($0.likedBy?.count ?? 0) > ($1.likedBy?.count ?? 0)
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addComment() async {
        guard !newComment.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let comment = Comment(
            id: UUID().uuidString,
            userId: userId,
            text: newComment,
            createdAt: Date(),
            likedBy: []
        )

        comments.append(comment)
        newComment = ""

        comments.sort {
            ($0.likedBy?.count ?? 0) > ($1.likedBy?.count ?? 0)
        }

        await saveComments()
    }

    private func toggleLike(for commentId: String) async {
        guard let index = comments.firstIndex(where: { $0.id == commentId }) else { return }

        var comment = comments[index]
        var liked = comment.likedBy ?? []

        if liked.contains(currentUserId) {
            liked.removeAll { $0 == currentUserId }
        } else {
            liked.append(currentUserId)
        }

        comment.likedBy = liked
        comments[index] = comment

        comments.sort {
            ($0.likedBy?.count ?? 0) > ($1.likedBy?.count ?? 0)
        }

        await saveComments()
    }

    private func saveComments() async {
        do {
            let commentDicts = try comments.map { comment -> [String: Any] in
                let data = try JSONEncoder().encode(comment)
                return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            }

            var firebaseDict: [String: Any] = [:]
            for (index, dict) in commentDicts.enumerated() {
                firebaseDict["\(index)"] = dict
            }

            try await database
                .child("posts")
                .child(post.id)
                .child("comments")
                .setValue(firebaseDict)

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CommentsView(post: Post(
        id: "testPostId",
        authorId: "user123",
        title: "Тестовий пост",
        description: "Це опис тестового поста",
        imageUrl: "https://example.com/image.jpg",
        isAIgenerated: false,
        aiConfidence: 0,
        tags: "",
        likesCount: 0,
        createdAt: Date()
    ))
}

