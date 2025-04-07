import Foundation
import FirebaseStorage
import FirebaseDatabase
import UIKit

final class PublicationService {
    static let shared = PublicationService()
    private init() {}

    private let storage = Storage.storage()
    private let database = Database.database().reference()
    
    private func makeGETRequest<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func makePOSTRequest<T: Decodable>(url: URL, body: [String: Any]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func fetchPostById(postId: String, completion: @escaping (Post?) -> Void) {
        guard var components = URLComponents(string: URLFormater.getURL("fetchPostById")) else {
            completion(nil)
            return
        }

        components.queryItems = [URLQueryItem(name: "postId", value: postId)]

        guard let url = components.url else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard
                let data = data,
                let post = try? JSONDecoder().decode(Post.self, from: data)
            else {
                completion(nil)
                return
            }
            completion(post)
        }.resume()
    }

    func fetchUserPosts(userId: String) async throws -> [Post] {
        guard var components = URLComponents(string: URLFormater.getURL("fetchUserPosts")) else {
            throw URLError(.badURL)
        }

        components.queryItems = [URLQueryItem(name: "userId", value: userId)]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        return try await makeGETRequest(url: url)
    }

    func fetchAllPostsSortedByDate() async throws -> [Post] {
        guard let url = URL(string: URLFormater.getURL("fetchAllPostsSortedByDate")) else {
            throw URLError(.badURL)
        }

        var decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        return try decoder.decode([Post].self, from: data)
    }

    func fetchLikedPosts(for userId: String) async throws -> [Post] {
        guard var components = URLComponents(string: URLFormater.getURL("fetchLikedPosts")) else {
            throw URLError(.badURL)
        }

        components.queryItems = [URLQueryItem(name: "userId", value: userId)]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        return try await makeGETRequest(url: url)
    }

    func fetchRecommendedPosts(userEmbedding: [Double], limit: Int = 10, similarityThreshold: Double = 0.4) async throws -> [Post] {
        guard let url = URL(string: URLFormater.getURL("fetchRecommendedPosts")) else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "embedding": userEmbedding,
            "limit": limit,
            "similarityThreshold": similarityThreshold
        ]

        return try await makePOSTRequest(url: url, body: body)
    }

    func fetchSimilarPostsByText(_ query: String, limit: Int = 10, similarityThreshold: Double = 0.4, completion: @escaping ([Post]) -> Void) {
        guard let url = URL(string: URLFormater.getURL("fetchSimilarPostsByText")) else {
            completion([])
            return
        }

        let body: [String: Any] = [
            "query": query,
            "threshold": similarityThreshold,
            "limit": limit
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard
                let data = data,
                let posts = try? JSONDecoder().decode([Post].self, from: data)
            else {
                completion([])
                return
            }

            completion(posts)
        }.resume()
    }

    func fetchPostsFromSubscriptions(for userId: String, completion: @escaping (Result<[Post], Error>) -> Void) {
        guard var components = URLComponents(string: "https://fetchpostsfromsubscriptions-vqfzkomcjq-ey.a.run.app") else {
            completion(.failure(NSError(domain: "URL", code: -1)))
            return
        }

        components.queryItems = [
            URLQueryItem(name: "userId", value: userId)
        ]

        guard let url = components.url else {
            completion(.failure(NSError(domain: "URL", code: -2)))
            return
        }

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(NSError(domain: "DataError", code: -3)))
                    return
                }

                do {
                    let posts = try JSONDecoder().decode([Post].self, from: data)
                    completion(.success(posts))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func uploadImageToServer(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Не вдалося конвертувати зображення."
            ])))
            return
        }

        let base64String = imageData.base64EncodedString()
        guard let url = URL(string: URLFormater.getURL("uploadImage")) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        let body = ["imageBase64": base64String]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let imageUrl = json["imageUrl"] as? String
            else {
                completion(.failure(NSError(domain: "ImageError", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Не вдалося прочитати відповідь сервера."
                ])))
                return
            }

            completion(.success(imageUrl))
        }.resume()
    }

    func uploadPost(_ post: Post, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: URLFormater.getURL("uploadPost")) else {
            completion(NSError(domain: "UploadError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Некоректна URL функції."
            ]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(post)
        } catch {
            completion(error)
            return
        }

        URLSession.shared.dataTask(with: request) { _, _, error in
            DispatchQueue.main.async {
                completion(error)
            }
        }.resume()
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
