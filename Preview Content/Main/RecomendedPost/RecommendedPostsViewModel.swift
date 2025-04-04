//
//  RecommendedPostsViewModel.swift
//  Diploma
//
//  Created by Orest Palii on 04.04.2025.
//

import Foundation
import FirebaseAuth

@MainActor
final class RecommendedPostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false

    func loadRecommendedPosts(limit: Int = 10) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        do {
            let user = try await FirebaseUserService.shared.fetchUserProfile(uid: userId)
            FirebasePostService.shared.fetchRecommendedPosts(for: user.embedding ?? [], limit: limit) { [weak self] posts in
                Task { @MainActor in
                    self?.posts = posts
                    self?.isLoading = false
                }
            }
        } catch {
            print("❌ Не вдалося завантажити embedding користувача:", error.localizedDescription)
            isLoading = false
        }
    }
}
