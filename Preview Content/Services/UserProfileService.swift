import Foundation
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import UIKit

class UserProfileService {
    static let shared = UserProfileService()
    private init() {}

    func createUserProfile(email: String, interests: [String], avatarImage: UIImage, embedding: [Double], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        uploadAvatarImage(avatarImage, uid: uid) { result in
            switch result {
            case .success(let avatarURL):
                let profile = UserProfileDTO(
                    uid: uid,
                    email: email,
                    interests: interests,
                    embedding: embedding,
                    avatarURL: avatarURL,
                    createdAt: Date().timeIntervalSince1970
                )
                self.saveProfileToDatabase(profile: profile, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func checkIfUserProfileExists(uid: String, completion: @escaping (Bool) -> Void) {
        let ref = Database.database().reference().child("users/\(uid)")
        ref.observeSingleEvent(of: .value) { snapshot in
            completion(snapshot.exists())
        }
    }

    private func uploadAvatarImage(_ image: UIImage, uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        let resizedImage = image.resize(to: CGSize(width: 256, height: 256))
        guard let data = resizedImage.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageConversionError", code: -1)))
            return
        }
    
        let ref = Storage.storage().reference().child("avatars/\(uid).jpg")
        ref.putData(data, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                ref.downloadURL { url, error in
                    if let url = url {
                        completion(.success(url.absoluteString))
                    } else {
                        completion(.failure(error ?? NSError(domain: "URLGenerationError", code: -2)))
                    }
                }
            }
        }
    }


    private func saveProfileToDatabase(profile: UserProfileDTO, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = Database.database().reference().child("users/\(profile.uid)")
        do {
            let data = try JSONEncoder().encode(profile)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            ref.setValue(dict) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func updateUserEmbedding(with postEmbedding: [Double], alpha: Float = 0.1) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let ref = Database.database().reference().child("users/\(uid)")
        
        let snapshot = try await ref.getDataAsync()
        
        guard let dict = snapshot.value as? [String: Any],
              let data = try? JSONSerialization.data(withJSONObject: dict),
              var profile = try? JSONDecoder().decode(UserProfileDTO.self, from: data),
              profile.embedding.count == postEmbedding.count
        else { return }

        // Оновлюємо embedding
        let updatedEmbedding = UserEmbeddingHelper.updatedEmbedding(
            userEmbedding: profile.embedding.map { Float($0) },
            postEmbedding: postEmbedding.map { Float($0) },
            alpha: alpha
        ).map { Double($0) }

        profile.embedding = updatedEmbedding

        let updatedData = try JSONEncoder().encode(profile)
        let updatedDict = try JSONSerialization.jsonObject(with: updatedData) as? [String: Any] ?? [:]
        try await ref.setValue(updatedDict)
    }

}

extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized ?? self
    }
}
