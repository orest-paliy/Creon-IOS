import Foundation
import SwiftUI

class CreatePostViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var prompt = ""
    @Published var image: UIImage?
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var didFinishPosting = false

    let gptService = ChatGPTService()

    func generateImageFromPrompt() {
        isUploading = true
        gptService.generateImageBase64(fromTags: [], customPrompt: prompt) { [weak self] image in
            DispatchQueue.main.async {
                self?.isUploading = false
                if let image = image {
                    self?.image = image
                } else {
                    self?.errorMessage = "Не вдалося згенерувати зображення"
                }
            }
        }
    }

    func createPost(authorId: String) {
        guard let image = image else {
            errorMessage = "Будь ласка, виберіть або згенеруйте зображення."
            return
        }

        isUploading = true

        PublicationService.shared.uploadImageToServer(image) { [weak self] result in
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
        let wasGenerated = !prompt.trimmingCharacters(in: .whitespaces).isEmpty

        gptService.generateTagString(from: imageUrl) { [weak self] tagString in
            self?.gptService.aiConfidenceLevel(from: imageUrl) { confidence in
                self?.gptService.generateEmbedding(from: tagString) { embedding in
                    let post = Post(
                        id: UUID().uuidString,
                        authorId: authorId,
                        title: self?.title ?? "",
                        description: self?.description ?? "",
                        imageUrl: imageUrl,
                        isAIgenerated: wasGenerated || confidence >= 50,
                        aiConfidence: wasGenerated ? 100 : confidence,
                        tags: tagString,
                        embedding: embedding,
                        comments: [],
                        likesCount: 0,
                        likedBy: [],
                        createdAt: Date(),
                        updatedAt: nil
                    )

                    PublicationService.shared.uploadPost(post) { error in
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
