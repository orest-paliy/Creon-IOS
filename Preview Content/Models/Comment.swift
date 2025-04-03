import Foundation

struct Comment: Identifiable, Codable {
    let id: String
    let userId: String
    let text: String
    let createdAt: Date
    var likedBy: [String]? = []
}
