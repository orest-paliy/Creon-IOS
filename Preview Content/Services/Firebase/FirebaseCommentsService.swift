//
//  FirebaseCommentsService.swift
//  Diploma
//
//  Created by Orest Palii on 04.04.2025.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

final class FirebaseCommentsService {
    static let shared = FirebaseCommentsService()
    private let database = Database.database().reference()

    private init() {}

    func fetchComments(for postId: String) async throws -> [Comment] {
        let ref = database.child("posts/\(postId)/comments")
        let snapshot = try await ref.getDataAsync()

        let sortedChildren = snapshot.children
            .compactMap { $0 as? DataSnapshot }
            .sorted { Int($0.key) ?? 0 < Int($1.key) ?? 0 }

        var comments: [Comment] = []

        for snap in sortedChildren {
            guard
                let dict = snap.value as? [String: Any],
                let data = try? JSONSerialization.data(withJSONObject: dict),
                let comment = try? JSONDecoder().decode(Comment.self, from: data)
            else { continue }

            comments.append(comment)
        }

        return comments
    }

    func saveComments(_ comments: [Comment], for postId: String) async throws {
        let commentDicts = try comments.map { comment -> [String: Any] in
            let data = try JSONEncoder().encode(comment)
            return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        }

        var firebaseDict: [String: Any] = [:]
        for (index, dict) in commentDicts.enumerated() {
            firebaseDict["\(index)"] = dict
        }

        try await database
            .child("posts")
            .child(postId)
            .child("comments")
            .setValue(firebaseDict)
    }
}
