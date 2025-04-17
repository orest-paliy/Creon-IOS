import Foundation
import UIKit

class ChatGPTService {
    
    //MARK: AI image auto description
    func generateTagString(from imageUrl: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: URLFormater.getURL("generateTagString")) else {
            completion("")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["imageUrl": imageUrl]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("GPT request error:", error.localizedDescription)
                completion("")
                return
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let description = json["description"] as? String
            else {
                print("GPT parsing error")
                completion("")
                return
            }

            print("GPT Raw Tag String:\n\(description)")
            completion(description.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
    

    
    //MARK: AI generation Confidance
    func aiConfidenceLevel(from imageUrl: String, completion: @escaping (Int) -> Void) {
        guard let url = URL(string: URLFormater.getURL("aiConfidenceLevel")) else {
            completion(0)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["imageUrl": imageUrl]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("AI confidence request error:", error.localizedDescription)
                completion(0)
                return
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let confidence = json["confidence"] as? Int
            else {
                print("AI confidence parsing error")
                completion(0)
                return
            }

            print("AI Confidence Level: \(confidence)%")
            completion(confidence)
        }.resume()
    }
    
    func generateEmbedding(from text: String, completion: @escaping ([Double]) -> Void) {
        guard let url = URL(string: URLFormater.getURL("generateTextEmbedding")) else {
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["text": text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let embedding = json["embedding"] as? [Double]
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
        
        guard let url = URL(string: URLFormater.getURL("generateAvatarImageBase64")) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "tags": tags,
            "customPrompt": customPrompt ?? ""
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let base64String = json["base64Image"] as? String,
                let imageData = Data(base64Encoded: base64String),
                let image = UIImage(data: imageData)
            else {
                completion(nil)
                return
            }

            completion(image)
        }.resume()
    }
}
