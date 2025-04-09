//
//  NewSearchViewModel.swift
//  Diploma
//
//  Created by Orest Palii on 08.04.2025.
//

import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var searchQuery: String = ""
    @Published var isSearching = false
    @Published var isLoading = false
    @Published var lastKey: String? = nil
    @Published var allPostsLoaded = false
    
    private var allPosts: [Post] = []
    private let pageSize = 10
    private var currentPage = 0

    func loadInitialPosts() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            allPosts = try await PublicationService.shared.fetchAllPostsSortedByDate()
            posts = Array(allPosts.prefix(pageSize))
            currentPage = 1
            allPostsLoaded = posts.count == allPosts.count
        } catch {
            print("Помилка при завантаженні:", error.localizedDescription)
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
    
    func performSearch() {
        isLoading = true
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            isSearching = false
            isLoading = false
            return
        }

        isSearching = true

        PublicationService.shared.fetchSimilarPostsByText(searchQuery) { [weak self] results in
            DispatchQueue.main.async {
                self?.posts = results
                self?.isLoading = false
            }
        }
    }

    func clearSearch() {
        searchQuery = ""
        isSearching = false
        posts = []
        lastKey = nil
        Task {
            await loadInitialPosts()
        }
    }

}
