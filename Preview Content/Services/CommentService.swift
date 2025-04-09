//
//  FirebaseCommentsService.swift
//  Diploma
//
//  Created by Orest Palii on 04.04.2025.
//

import Foundation

final class CommentService {
    static let shared = CommentService()

    private init() {}

    func fetchComments(for postId: String) async throws -> [Comment] {
        guard var components = URLComponents(string: URLFormater.getURL("fetchcomments")) else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "postId", value: postId)]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Comment].self, from: data)
    }

    func saveComments(_ comments: [Comment], for postId: String) async throws {
        guard let url = URL(string: URLFormater.getURL("savecomments")) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "postId": postId,
            "comments": try comments.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) }
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        _ = try await URLSession.shared.data(for: request)
    }
}
