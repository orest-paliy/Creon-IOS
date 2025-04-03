import Foundation
import SwiftUI

class CreatePostViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var image: UIImage?
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var didFinishPosting = false

    let gptService = GPTTagService()

    func createPost(authorId: String) {
        guard let image = image else {
            errorMessage = "Будь ласка, виберіть зображення."
            return
        }

        isUploading = true

        FirebaseUserService.shared.uploadImage(image) { [weak self] result in
            switch result {
            case .success(let imageUrl):
                self?.generatePostData(imageUrl: imageUrl, authorId: authorId)
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func generatePostData(imageUrl: String, authorId: String) {
        gptService.generateTagString(from: imageUrl) { [weak self] tagString in
            self?.gptService.aiConfidenceLevel(from: imageUrl) { confidence in
                self?.gptService.generateEmbedding(from: tagString) { embedding in
                    let isAI = confidence >= 50

                    let post = Post(
                        id: UUID().uuidString,
                        authorId: authorId,
                        title: self?.title ?? "",
                        description: self?.description ?? "",
                        imageUrl: imageUrl,
                        isAIgenerated: isAI,
                        aiConfidence: confidence,
                        tags: tagString,
                        embedding: embedding,
                        comments: [],
                        likesCount: 0,
                        likedBy: [],
                        createdAt: Date(),
                        updatedAt: nil
                    )

                    FirebaseUserService.shared.uploadPost(post) { error in
                        DispatchQueue.main.async {
                            self?.isUploading = false
                            if let error = error {
                                self?.errorMessage = error.localizedDescription
                            } else {
                                self?.didFinishPosting = true
                            }
                        }
                    }
                }
            }
        }
    }
}
