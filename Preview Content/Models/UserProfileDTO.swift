import Foundation
import FirebaseDatabaseInternal

struct UserProfileDTO: Codable {
    let uid: String
    let email: String
    let interests: [String]
    var embedding: [Double]
    let avatarURL: String
    let createdAt: TimeInterval
    var subscriptions: [String]?
    var followers: [String]?
}

//MARK: - Correcting arrays of followers if they are empty
extension UserProfileDTO {
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String: Any],
              let uid = dict["uid"] as? String,
              let email = dict["email"] as? String,
              let interests = dict["interests"] as? [String],
              let embedding = dict["embedding"] as? [Double],
              let avatarURL = dict["avatarURL"] as? String,
              let createdAt = dict["createdAt"] as? TimeInterval
        else {
            return nil
        }

        let subscriptionsDict = dict["subscriptions"] as? [String: Any]
        let followersDict = dict["followers"] as? [String: Any]

        self.uid = uid
        self.email = email
        self.interests = interests
        self.embedding = embedding
        self.avatarURL = avatarURL
        self.createdAt = createdAt
        self.subscriptions = subscriptionsDict.map { Array($0.keys) }
        self.followers = followersDict.map { Array($0.keys) }
    }
}
