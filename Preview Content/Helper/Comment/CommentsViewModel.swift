//
//  CommentsViewModel.swift
//  Diploma
//
//  Created by Orest Palii on 04.04.2025.
//

import Foundation
import FirebaseAuth

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var newComment: String = ""
    @Published var errorMessage: String?

    let postId: String
    let currentUserId: String = Auth.auth().currentUser?.uid ?? ""

    init(postId: String) {
        self.postId = postId
    }

    func fetchComments() async {
        do {
            let fetched = try await FirebaseCommentsService.shared.fetchComments(for: postId)
            comments = fetched.sorted { ($0.likedBy?.count ?? 0) > ($1.likedBy?.count ?? 0) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addComment() async {
        guard !newComment.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let comment = Comment(
            id: UUID().uuidString,
            userId: currentUserId,
            text: newComment,
            createdAt: Date(),
            likedBy: []
        )

        comments.append(comment)
        newComment = ""
        sortComments()

        await saveComments()
    }

    func toggleLike(for commentId: String) async {
        guard let index = comments.firstIndex(where: { $0.id == commentId }) else { return }

        var likedBy = comments[index].likedBy ?? []

        if likedBy.contains(currentUserId) {
            likedBy.removeAll { $0 == currentUserId }
        } else {
            likedBy.append(currentUserId)
        }

        comments[index].likedBy = likedBy
        sortComments()

        await saveComments()
    }

    private func sortComments() {
        comments.sort {
            ($0.likedBy?.count ?? 0) > ($1.likedBy?.count ?? 0)
        }
    }

    private func saveComments() async {
        do {
            try await FirebaseCommentsService.shared.saveComments(comments, for: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
