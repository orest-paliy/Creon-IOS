//
//  SubscriptionPostsViewModel.swift
//  Diploma
//
//  Created by Orest Palii on 04.04.2025.
//

import Foundation

@MainActor
final class SubscriptionPostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var allPostsLoaded = false
    
    private var allPosts: [Post] = []
    private var currentPage: Int = 0
    private let pageSize = 10

    func loadInitialPosts() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            guard let currentUserId = FirebaseUserService.shared.currentUserId else { return }

            // 1. Завантажити список ID підписок
            var subscriptions: [String] = []
            let group = DispatchGroup()
            group.enter()
            FirebaseUserService.shared.fetchSubscriptions(for: currentUserId) { ids in
                subscriptions = ids
                group.leave()
            }
            group.wait()

            // 2. Завантажити всі пости
            let allFetchedPosts = try await FirebasePostService.shared.fetchAllPostsSortedByDate()

            // 3. Відфільтрувати лише пости підписок
            self.allPosts = allFetchedPosts.filter { subscriptions.contains($0.authorId) }

            // 4. Взяти першу сторінку
            self.posts = Array(allPosts.prefix(pageSize))
            self.currentPage = 1
            self.allPostsLoaded = posts.count == allPosts.count
        } catch {
            print("Помилка при завантаженні підписок:", error.localizedDescription)
        }
    }

    func loadMorePosts() async {
        guard !isLoading, !allPostsLoaded else { return }
        isLoading = true
        defer { isLoading = false }

        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, allPosts.count)

        guard startIndex < endIndex else {
            allPostsLoaded = true
            return
        }

        let newPosts = Array(allPosts[startIndex..<endIndex])
        posts.append(contentsOf: newPosts)
        currentPage += 1
        allPostsLoaded = posts.count == allPosts.count
    }
}

