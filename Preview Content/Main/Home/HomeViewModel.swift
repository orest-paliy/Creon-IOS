import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var searchQuery: String = ""
    @Published var isSearching = false
    @Published var isLoading = false
    @Published var lastKey: String? = nil

    func loadInitialPosts(limit: UInt = 10) async {
        guard posts.isEmpty else { return }
        isLoading = true
        do {
            let fetched = try await FirebasePostService.shared.fetchPostsByKey(limit: limit, startAfter: nil)
            self.posts = fetched
            self.lastKey = fetched.last?.id
        } catch {
            print("❌ Failed to load posts:", error.localizedDescription)
        }
        isLoading = false
    }

    func loadMorePosts(limit: UInt = 10) async {
        guard !isLoading else { return }
        isLoading = true
        do {
            let fetched = try await FirebasePostService.shared.fetchPostsByKey(limit: limit, startAfter: lastKey)
            let newPosts = fetched.filter { newPost in
                !posts.contains(where: { $0.id == newPost.id })
            }
            self.posts.append(contentsOf: newPosts)
            self.lastKey = fetched.last?.id
        } catch {
            print("❌ Failed to load more posts:", error.localizedDescription)
        }
        isLoading = false
    }

    func performSearch() {
        isLoading = true
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            isSearching = false
            isLoading = false
            return
        }

        isSearching = true

        FirebasePostService.shared.fetchSimilarPostsByEmbedding(for: searchQuery) { [weak self] results in
            Task { @MainActor in
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
