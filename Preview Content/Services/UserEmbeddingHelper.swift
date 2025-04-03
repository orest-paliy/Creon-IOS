import Foundation

struct UserEmbeddingHelper {
    static func updatedEmbedding(userEmbedding: [Float], postEmbedding: [Float], alpha: Float = 0.1) -> [Float] {
        guard userEmbedding.count == postEmbedding.count else { return userEmbedding }
        return zip(userEmbedding, postEmbedding).map { (u, p) in
            (1 - alpha) * u + alpha * p
        }
    }
}
