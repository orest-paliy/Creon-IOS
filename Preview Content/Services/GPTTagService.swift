import Foundation
import UIKit

class GPTTagService {
    private let apiKey = APIConfig.loadAPIKey() ?? ""
    
    func generateAvatarPrompt(from tags: [String]) -> String {
        return """
        Згенеруй фото профілю вигаданої людини, яка цікавиться наступними темами: \(tags.joined(separator: ", ")).
        Фото повинно виглядати сучасно, креативно, відповідно до своїх інтересів. Уникай тексту, складного фону чи надто реалістичного зображення. Стиль: легкий, абстрактний або мінімалістичний. Розмір: 100x100 пікселів.
        """
    }
    
    //MARK: AI image auto description
    func generateTagString(from imageUrl: String, completion: @escaping (String) -> Void) {
        let instruction = """
        Опиши коротко, що зображено на фото. Не вигадуй. Просто скажи, що видно на зображенні: кімната, предмети, кольори, атмосфера. Одне речення.
        """
        
        sendChatRequest(with: imageUrl, instruction: instruction) { responseText in
            print("GPT Raw Tag String:\n\(responseText)")
            completion(responseText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    //MARK: AI generation Confidance
    func aiConfidenceLevel(from imageUrl: String, completion: @escaping (Int) -> Void) {
        let instruction = """
        Проаналізуй це зображення за посиланням: \(imageUrl).
        На скільки відсотків (від 0 до 100) воно ймовірно згенероване штучним інтелектом?
        Відповідай лише числом без знаку %, без коментарів. Наприклад: 78
        """
        
        sendChatRequest(with: imageUrl, instruction: instruction) { response in
            let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
            let number = Int(trimmed) ?? 0
            completion(min(max(number, 0), 100)) // гарантуємо 0...100
        }
    }
    
    //MARK: Generation of embedding array
    func generateEmbedding(from text: String, completion: @escaping ([Double]) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/embeddings") else {
            completion([])
            return
        }

        let body: [String: Any] = [
            "input": text,
            "model": "text-embedding-3-small"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let dataArray = json["data"] as? [[String: Any]],
                let embedding = dataArray.first?["embedding"] as? [Double]
            else {
                completion([])
                return
            }
            completion(embedding)
        }.resume()
    }
    
    
    //MARK: User profile generation
    func generateImageBase64(fromTags tags: [String] = [],
                                 customPrompt: String? = nil,
                                 completion: @escaping (UIImage?) -> Void) {
            
            let promptToUse: String
            if let custom = customPrompt, !custom.trimmingCharacters(in: .whitespaces).isEmpty {
                promptToUse = custom
            } else {
                promptToUse = generateAvatarPrompt(from: tags)
            }

            guard let url = URL(string: "https://api.openai.com/v1/images/generations") else {
                completion(nil)
                return
            }

            let body: [String: Any] = [
                "model": "dall-e-3",
                "prompt": promptToUse,
                "n": 1,
                "size": "1024x1024",
                "response_format": "b64_json"
            ]

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { data, _, _ in
                guard
                    let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let dataArray = json["data"] as? [[String: Any]],
                    let b64String = dataArray.first?["b64_json"] as? String,
                    let imageData = Data(base64Encoded: b64String),
                    let image = UIImage(data: imageData)
                else {
                    completion(nil)
                    return
                }
                completion(image)
            }.resume()
        }
    
    //MARK: Web request
    private func sendChatRequest(with imageUrl: String, instruction: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return }
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        let content: [[String: Any]] = [
            ["type": "image_url", "image_url": ["url": imageUrl]],
            ["type": "text", "text": instruction]
        ]
        
        let message: [String: Any] = [
            "role": "user",
            "content": content
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4-turbo",
            "messages": [message],
            "max_tokens": 500
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("GPT request error:", error)
                completion("")
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                print("GPT parsing error.")
                completion("")
                return
            }
            
            completion(content)
        }.resume()
    }

}
