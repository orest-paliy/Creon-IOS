import Foundation
import FirebaseDatabase

final class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [Post] = []
    @Published var isLoading = false

    func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isLoading = true

        let queryTags = searchText
            .lowercased()
            .split(separator: " ")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        Database.database().reference().child("posts").observeSingleEvent(of: .value) { snapshot in
            var foundPosts: [Post] = []
            var seenIds: Set<String> = []

            for child in snapshot.children {
                guard
                    let snap = child as? DataSnapshot,
                    let dict = snap.value as? [String: Any],
                    let data = try? JSONSerialization.data(withJSONObject: dict),
                    let post = try? JSONDecoder().decode(Post.self, from: data)
                else { continue }

                let postTags = post.tags
                    .lowercased()
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }

                if !Set(queryTags).isDisjoint(with: postTags), !seenIds.contains(post.id) {
                    foundPosts.append(post)
                    seenIds.insert(post.id)
                }
            }

            DispatchQueue.main.async {
                self.searchResults = foundPosts
                self.isLoading = false
            }
        }
    }
}
