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
}
