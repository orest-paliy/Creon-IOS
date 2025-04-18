import Foundation
import Photos
import UIKit

final class PublicationService {
    static let shared = PublicationService()
    private init() {}
    
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

    func fetchPostById(postId: String) async throws -> Post? {
        guard var components = URLComponents(string: URLFormater.getURL("fetchPostById")) else {
            return nil
        }

        components.queryItems = [URLQueryItem(name: "postId", value: postId)]

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request)

        let post = try JSONDecoder().decode(Post.self, from: data)
        return post
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

    func fetchRecommendedPosts(userEmbedding: [Double], limit: Int = 11, similarityThreshold: Double = 0.4) async throws -> [Post] {
        guard let url = URL(string: URLFormater.getURL("getRecommendedPosts")) else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "embedding": userEmbedding,
            "limit": limit
        ]

        return try await makePOSTRequest(url: url, body: body)
    }

    func fetchSimilarPostsByText(_ query: String, limit: Int = 10, completion: @escaping ([Post]) -> Void) {
        guard let url = URL(string: URLFormater.getURL("getSimilarPostsByTextInput")) else {
            completion([])
            return
        }

        let body: [String: Any] = [
            "query": query,
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
    
    func deletePost(id: String, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: URLFormater.getURL("deletePost")) else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["postId": id]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, _, error in
            DispatchQueue.main.async {
                completion(error)
            }
        }.resume()
    }
    
    func saveImageToGallery(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data), error == nil else {
                print("Помилка завантаження зображення:", error?.localizedDescription ?? "")
                return
            }

            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized || status == .limited else {
                    print("Немає дозволу на доступ до фото")
                    return
                }

                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                print("Фото збережено в галерею")
            }
        }.resume()
    }
}
