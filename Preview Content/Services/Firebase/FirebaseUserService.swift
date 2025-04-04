import Foundation
import FirebaseAuth
import FirebaseDatabase

final class FirebaseUserService {
    static let shared = FirebaseUserService()
    private init() {}

    private let database = Database.database().reference()

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    var currentUserEmail: String? {
        Auth.auth().currentUser?.email
    }

    func fetchEmail(for uid: String) async -> String {
        let ref = database.child("users").child(uid).child("email")
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
            let ref = database.child("users").child(uid)
            ref.observeSingleEvent(of: .value) { snapshot in
                guard let dict = snapshot.value as? [String: Any] else {
                    continuation.resume(throwing: NSError(domain: "UserProfileError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Профіль не знайдено"]))
                    return
                }

                guard
                    let uid = dict["uid"] as? String,
                    let email = dict["email"] as? String,
                    let interests = dict["interests"] as? [String],
                    let embedding = dict["embedding"] as? [Double],
                    let avatarURL = dict["avatarURL"] as? String,
                    let createdAt = dict["createdAt"] as? TimeInterval
                else {
                    continuation.resume(throwing: NSError(domain: "UserProfileError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Неправильні дані профілю"]))
                    return
                }

                let subscriptionsDict = dict["subscriptions"] as? [String: Any]
                let followersDict = dict["followers"] as? [String: Any]

                let user = UserProfileDTO(
                    uid: uid,
                    email: email,
                    interests: interests,
                    embedding: embedding,
                    avatarURL: avatarURL,
                    createdAt: createdAt,
                    subscriptions: subscriptionsDict.map { Array($0.keys) },
                    followers: followersDict.map { Array($0.keys) }
                )

                continuation.resume(returning: user)
            }
        }
    }

    func logout() throws {
        try Auth.auth().signOut()
    }
    
    //MARK: Subscription & Following
    
    // MARK: - Subscribe to user
    func subscribe(to userId: String, from currentUserId: String, completion: @escaping (Error?) -> Void) {
        let updates: [String: Any?] = [
            "/users/\(currentUserId)/subscriptions/\(userId)": true,
            "/users/\(userId)/followers/\(currentUserId)": true
        ]

        database.updateChildValues(updates.compactMapValues { $0 }, withCompletionBlock: { error, _ in
            completion(error)
        })
    }

    // MARK: - Unsubscribe from user
    func unsubscribe(from userId: String, by currentUserId: String, completion: @escaping (Error?) -> Void) {
        let updates: [String: Any?] = [
            "/users/\(currentUserId)/subscriptions/\(userId)": nil,
            "/users/\(userId)/followers/\(currentUserId)": nil
        ]

        database.updateChildValues(updates.compactMapValues { $0 }, withCompletionBlock: { error, _ in
            completion(error)
        })
    }

    // MARK: - Check subscription status
    func isSubscribed(to userId: String, from currentUserId: String, completion: @escaping (Bool) -> Void) {
        database.child("users/\(currentUserId)/subscriptions/\(userId)").observeSingleEvent(of: .value) { snapshot in
            completion(snapshot.exists())
        }
    }

    // MARK: - Fetch list of subscriptions
    func fetchSubscriptions(for userId: String, completion: @escaping ([String]) -> Void) {
        database.child("users/\(userId)/subscriptions").observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            let ids = Array(data.keys)
            completion(ids)
        }
    }

    // MARK: - Fetch list of followers
    func fetchFollowers(for userId: String, completion: @escaping ([String]) -> Void) {
        database.child("users/\(userId)/followers").observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            let ids = Array(data.keys)
            completion(ids)
        }
    }
}
