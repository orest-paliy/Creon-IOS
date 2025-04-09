import Foundation
import UIKit
import FirebaseAuth

final class UserProfileService {
    static let shared = UserProfileService()
    private init() {}

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    var currentUserEmail: String? {
        Auth.auth().currentUser?.email
    }
    
    func logout() throws {
        try Auth.auth().signOut()
    }
    

    func fetchUserProfile(uid: String) async throws -> User {
        guard var components = URLComponents(string: URLFormater.getURL("fetchuserprofile")) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "uid", value: uid)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(User.self, from: data)
    }

    func createUserProfile(
        email: String,
        interests: [String],
        avatarURL: String,
        embedding: [Double],
        subscriptions: [String] = [],
        followers: [String] = [],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "UserError", code: -1)))
            return
        }

        guard let url = URL(string: URLFormater.getURL("createUserProfile")) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        let body: [String: Any] = [
            "uid": uid,
            "email": email,
            "interests": interests,
            "embedding": embedding,
            "avatarURL": avatarURL,
            "createdAt": Date().timeIntervalSince1970,
            "subscriptions": subscriptions,
            "followers": followers
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }.resume()
    }
    
    private func saveProfileToDatabase(
        profile: User,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        createUserProfile(
            email: profile.email,
            interests: profile.interests,
            avatarURL: profile.avatarURL,
            embedding: profile.embedding,
            subscriptions: profile.subscriptions ?? [],
            followers: profile.followers ?? [],
            completion: completion
        )
    }
    
    func updateUserEmbedding(with postEmbedding: [Double], alpha: Float = 0.1) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var profile = try await fetchUserProfile(uid: uid)
        
        // Оновлюємо embedding
        let updatedEmbedding = updatedEmbedding(
            userEmbedding: profile.embedding.map { Float($0) },
            postEmbedding: postEmbedding.map { Float($0) },
            alpha: alpha
        ).map { Double($0) }

        profile.embedding = updatedEmbedding

        createUserProfile(
            email: profile.email,
            interests: profile.interests,
            avatarURL: profile.avatarURL,
            embedding: profile.embedding,
            subscriptions: profile.subscriptions ?? [],
            followers: profile.followers ?? [],
            completion: {_ in }
        )
    }
    
    func checkIfUserProfileExists(uid: String, completion: @escaping (Bool) -> Void) {
        guard var components = URLComponents(string: URLFormater.getURL("checkifuserprofileexists")) else {
            completion(false)
            return
        }

        components.queryItems = [URLQueryItem(name: "uid", value: uid)]

        guard let url = components.url else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let exists = json["exists"] as? Bool else {
                completion(false)
                return
            }

            completion(exists)
        }.resume()
    }

    func uploadAvatarImage(_ image: UIImage, uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        let resizedImage = image.resize(to: CGSize(width: 256, height: 256))
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageConversionError", code: -1)))
            return
        }

        let base64String = imageData.base64EncodedString()
        guard let url = URL(string: URLFormater.getURL("uploadavatarimage")) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "imageBase64": base64String,
            "uid": uid
        ]

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
                completion(.failure(NSError(domain: "ServerError", code: -2)))
                return
            }

            completion(.success(imageUrl))
        }.resume()
    }


    
    func subscribe(to userId: String, from currentUserId: String, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: URLFormater.getURL("subscribeToUser")) else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "currentUserId": currentUserId,
            "userIdToSubscribe": userId
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                completion(error)
            }
        }.resume()
    }


    func unsubscribe(from userId: String, by currentUserId: String, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: URLFormater.getURL("unsubscribeFromUser")) else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "currentUserId": currentUserId,
            "userIdToUnsubscribe": userId
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, _, error in
            DispatchQueue.main.async {
                completion(error)
            }
        }.resume()
    }

    func isSubscribed(to userId: String, from currentUserId: String, completion: @escaping (Bool) -> Void) {
        guard var components = URLComponents(string: URLFormater.getURL("isSubscribed")) else {
            completion(false)
            return
        }

        components.queryItems = [
            URLQueryItem(name: "currentUserId", value: currentUserId),
            URLQueryItem(name: "targetUserId", value: userId)
        ]

        guard let url = components.url else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            var result = false
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let isSubscribed = json["isSubscribed"] as? Bool {
                result = isSubscribed
            }
            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }

    func fetchSubscriptions(for userId: String, completion: @escaping ([String]) -> Void) {
        guard var components = URLComponents(string: URLFormater.getURL("fetchSubscriptions")) else {
            completion([])
            return
        }

        components.queryItems = [URLQueryItem(name: "userId", value: userId)]

        guard let url = components.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            var ids: [String] = []
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let subscriptions = json["subscriptions"] as? [String] {
                ids = subscriptions
            }
            DispatchQueue.main.async {
                completion(ids)
            }
        }.resume()
    }

    func fetchFollowers(for userId: String, completion: @escaping ([String]) -> Void) {
        guard var components = URLComponents(string: URLFormater.getURL("fetchFollowers")) else {
            completion([])
            return
        }

        components.queryItems = [URLQueryItem(name: "userId", value: userId)]

        guard let url = components.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            var ids: [String] = []
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let followers = json["followers"] as? [String] {
                ids = followers
            }
            DispatchQueue.main.async {
                completion(ids)
            }
        }.resume()
    }

    
    private func updatedEmbedding(userEmbedding: [Float], postEmbedding: [Float], alpha: Float = 0.1) -> [Float] {
        guard userEmbedding.count == postEmbedding.count else { return userEmbedding }
        return zip(userEmbedding, postEmbedding).map { (u, p) in
            (1 - alpha) * u + alpha * p
        }
    }
}
