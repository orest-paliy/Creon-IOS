//
//  GoogleVisionService.swift
//  Diploma
//
//  Created by Orest Palii on 17.04.2025.
//

import Foundation

final class GoogleVisionService {
    static let shared = GoogleVisionService()
    
    // MARK: - Google Vision SafeSearch
    func isImageUnsafe(from imageUrl: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: URLFormater.getURL("checkImageForUnsafeContent")) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["imageUrl": imageUrl]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("SafeSearch error:", error.localizedDescription)
                completion(false)
                return
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                let adult = json["adult"],
                let violence = json["violence"],
                let racy = json["racy"]
            else {
                print("SafeSearch parsing error")
                completion(false)
                return
            }

            print("SafeSearch result:", json)

            let flags = [adult, violence, racy]
            let isUnsafe = flags.contains(where: { $0 == "LIKELY" || $0 == "VERY_LIKELY" })

            completion(isUnsafe)
        }.resume()
    }

}
