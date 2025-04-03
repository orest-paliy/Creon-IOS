//
//  APIConfig.swift
//  Diploma
//
//  Created by Orest Palii on 03.04.2025.
//
import SwiftUI

struct APIConfig: Codable {
    let chatGPT: String

    static func loadAPIKey() -> String? {
        guard let url = Bundle.main.url(forResource: "APIConfig", withExtension: "json") else {
            print("❌ URL не знайдено: APIConfig.json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(APIConfig.self, from: data)
            print("✅ Ключ завантажено: \(config.chatGPT)")
            return config.chatGPT
        } catch {
            print("❌ Помилка при парсингу APIConfig.json: \(error.localizedDescription)")
            return nil
        }
    }
}
