import Foundation
import FirebaseStorage
import UIKit
import FirebaseAuth
import FirebaseDatabase

final class FirebaseUserService {
    static let shared = FirebaseUserService()
    private init() {}
    
    private let storage = Storage.storage()
    private let database = Database.database().reference()

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    var currentUserEmail: String? {
        Auth.auth().currentUser?.email
    }
    
    //MARK: User
    func fetchEmail(for uid: String) async -> String {
        let ref = Database.database().reference().child("users").child(uid).child("email")
        
        return await withCheckedContinuation { continuation in
            ref.observeSingleEvent(of: .value) { snapshot in
                if let email = snapshot.value as? String {
                    continuation.resume(returning: email)
                } else {
                    continuation.resume(returning: "unknown@email.com")
                }
            }
        }
    }
    
    func fetchUserProfile(uid: String) async throws -> UserProfileDTO {
            return try await withCheckedThrowingContinuation { continuation in
                let ref = Database.database().reference().child("users").child(uid)
                ref.observeSingleEvent(of: .value) { snapshot in
                    guard let dict = snapshot.value as? [String: Any] else {
                        continuation.resume(throwing: NSError(domain: "UserProfileError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Профіль не знайдено"]))
                        return
                    }

                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dict)
                        let user = try JSONDecoder().decode(UserProfileDTO.self, from: jsonData)
                        continuation.resume(returning: user)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    
    func logout() throws {
        try Auth.auth().signOut()
    }


    //MARK: Fetch posts
    func fetchUserPosts(userId: String) async throws -> [Post] {
        let snapshot = try await database.child("posts").getDataAsync()

        var posts: [Post] = []

        for child in snapshot.children {
            guard
                let snap = child as? DataSnapshot,
                let dict = snap.value as? [String: Any],
                let data = try? JSONSerialization.data(withJSONObject: dict)
            else {
                continue
            }

            do {
                let post = try JSONDecoder().decode(Post.self, from: data)
                if post.authorId == userId {
                    posts.append(post)
                } else {
                    print("⚠️ Ignored post with different authorId:", post.authorId)
                }
            } catch {
            }
        }
        return posts
    }
    
    func fetchPostsByKey(limit: UInt, startAfter lastKey: String?) async throws -> [Post] {
        var query = database.child("posts").queryOrderedByKey()

        if let lastKey = lastKey {
            query = query.queryStarting(afterValue: lastKey)
        }

        query = query.queryLimited(toFirst: limit)

        let snapshot = try await query.getDataAsync()
        var posts: [Post] = []

        for child in snapshot.children {
            guard
                let snap = child as? DataSnapshot,
                let dict = snap.value as? [String: Any],
                let data = try? JSONSerialization.data(withJSONObject: dict),
                let post = try? JSONDecoder().decode(Post.self, from: data)
            else { continue }

            posts.append(post)
        }

        return posts
    }

    func fetchSimilarPostsByEmbedding(for query: String, limit: Int = 10, similarityThreshold: Double = 0.4, completion: @escaping ([Post]) -> Void) {
        GPTTagService().generateEmbedding(from: query) { queryEmbedding in
            guard !queryEmbedding.isEmpty else {
                completion([])
                return
            }

            let ref = Database.database().reference().child("posts")

            ref.observeSingleEvent(of: .value) { snapshot in
                var scored: [(Post, Double)] = []

                for child in snapshot.children {
                    guard
                        let snap = child as? DataSnapshot,
                        let dict = snap.value as? [String: Any],
                        let data = try? JSONSerialization.data(withJSONObject: dict),
                        let post = try? JSONDecoder().decode(Post.self, from: data),
                        let postEmbedding = post.embedding,
                        postEmbedding.count == queryEmbedding.count
                    else { continue }
                    
                    if post.tags == query{
                        continue
                    }
                    
                    let sim = self.cosineSimilarity(queryEmbedding, postEmbedding)
                    print("\(post.title) sim = \(sim)")
                    if sim >= similarityThreshold {
                        scored.append((post, sim))
                    }
                }

                let sorted = scored.sorted { $0.1 > $1.1 }.prefix(limit).map { $0.0 }
                completion(sorted)
            }
        }
    }

    func fetchLikedPosts(for userId: String) async throws -> [Post] {
        let ref = Database.database().reference().child("posts")
        let snapshot = try await ref.getDataAsync()
        
        var likedPosts: [Post] = []

        for case let child as DataSnapshot in snapshot.children {
            guard
                let dict = child.value as? [String: Any],
                let data = try? JSONSerialization.data(withJSONObject: dict),
                var post = try? JSONDecoder().decode(Post.self, from: data)
            else { continue }

            if post.likedBy?.contains(userId) == true {
                likedPosts.append(post)
            }
        }

        return likedPosts
    }

    func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0.0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA != 0 && magnitudeB != 0 else { return 0.0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    
    //MARK: Post creation
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не вдалося конвертувати зображення."])))
            return
        }

        let imageId = UUID().uuidString
        let ref = storage.reference().child("posts/\(imageId).jpg")

        ref.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            ref.downloadURL { url, error in
                if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(error!))
                }
            }
        }
    }

    func uploadPost(_ post: Post, completion: @escaping (Error?) -> Void) {
        let postDict = try? JSONEncoder().encode(post)
        guard let data = postDict,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не вдалося серіалізувати пост."]))
            return
        }

        database.child("posts").child(post.id).setValue(json, withCompletionBlock: { _, error in
            completion(error as? Error)
        })
    }

}

extension DatabaseQuery {
    func getDataAsync() async throws -> DataSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            self.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
}


