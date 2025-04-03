import Foundation

struct Post: Identifiable, Codable, Equatable {
    let id: String
    let authorId: String
    let title: String
    let description: String
    let imageUrl: String
    let isAIgenerated: Bool
    let aiConfidence: Int
    var tags: String
    var embedding: [Double]? 
    var comments: [Comment]?
    var likesCount: Int
    var likedBy: [String]?
    let createdAt: Date
    var updatedAt: Date?

    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}
