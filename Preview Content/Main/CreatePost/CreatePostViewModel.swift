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
    @Published var didFinishStreaming = false
    @Published var generatedTagString = ""
    
    private let gptService = ChatGPTService()
    private let streamHandler = GPTStreamHandler()
    
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
    
    func createPost(userTitle: String, userDescription: String, authorId: String) {
        guard let image = image else {
            errorMessage = "Будь ласка, виберіть або згенеруйте зображення."
            return
        }
        
        isUploading = true
        
        PublicationService.shared.uploadImageToServer(image) { [weak self] result in
            switch result {
            case .success(let imageUrl):
                self?.generatePostData(imageUrl: imageUrl, userTitle: userTitle, userDescription: userDescription, authorId: authorId)
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func generatePostData(imageUrl: String, userTitle: String, userDescription: String, authorId: String) {
        let wasGenerated = !prompt.trimmingCharacters(in: .whitespaces).isEmpty
        var tagString = ""
        
        streamHandler.startStreaming(
            from: imageUrl,
            userTitle: userTitle,
            userDescription: userDescription,
            onChunk: { chunk in
                tagString += chunk
                self.generatedTagString.append(chunk)
            },
            onComplete: { [weak self] in
                guard let self = self else { return }
                self.didFinishStreaming = true
                
                let group = DispatchGroup()
                var isUnsafe: Bool?
                var confidence: Int?
                var embedding: [Double]?
                
                group.enter()
                GoogleVisionService.shared.isImageUnsafe(from: imageUrl) { result in
                    isUnsafe = result
                    group.leave()
                }
                
                group.enter()
                gptService.aiConfidenceLevel(from: imageUrl) { result in
                    confidence = result
                    group.leave()
                }
                
                group.enter()
                gptService.generateEmbedding(from: tagString) { result in
                    embedding = result
                    group.leave()
                }
                
                group.notify(queue: .main) {
                    self.isUploading = false
                    
                    if isUnsafe == nil || confidence == nil || embedding == nil {
                        self.errorMessage = "Помилка при обробці AI-запитів"
                        return
                    }
                    
                    if isUnsafe == true {
                        self.errorMessage = "Зображення містить заборонений контент"
                        return
                    }
                    
                    let post = Post(
                        id: UUID().uuidString,
                        authorId: authorId,
                        title: self.title,
                        description: self.description,
                        imageUrl: imageUrl,
                        isAIgenerated: wasGenerated || (confidence ?? 0) >= 50,
                        aiConfidence: wasGenerated ? 100 : (confidence ?? 0),
                        tags: tagString.trimmingCharacters(in: .whitespacesAndNewlines),
                        embedding: embedding ?? [],
                        comments: [],
                        likesCount: 0,
                        likedBy: [],
                        createdAt: Date(),
                        updatedAt: nil
                    )
                    
                    PublicationService.shared.uploadPost(post) { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self.errorMessage = error.localizedDescription
                            } else {
                                self.didFinishPosting = true
                            }
                        }
                    }
                }
            }
        )
    }
}
