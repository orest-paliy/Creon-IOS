import Foundation

struct User: Codable {
    let uid: String
    let email: String
    let interests: [String]
    var embedding: [Double]
    let avatarURL: String
    let createdAt: TimeInterval
    var subscriptions: [String]?
    var followers: [String]?
}

