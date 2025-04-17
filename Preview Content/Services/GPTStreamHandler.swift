//
//  GPTStreamHandler.swift
//  Diploma
//
//  Created by Orest Palii on 17.04.2025.
//
import SwiftUI

class GPTStreamHandler: NSObject, URLSessionDataDelegate {
    private var responseHandler: ((String) -> Void)?
    private var completionHandler: (() -> Void)?

    func startStreaming(from imageUrl: String,
                        onChunk: @escaping (String) -> Void,
                        onComplete: @escaping () -> Void) {
        guard let url = URL(string: URLFormater.getURL("generateTagStringStreaming")) else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = ["imageUrl": imageUrl]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        self.responseHandler = onChunk
        self.completionHandler = onComplete

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        session.dataTask(with: request).resume()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        DispatchQueue.main.async {
            self.responseHandler?(chunk)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.completionHandler?()
        }
        if let error = error {
            print("Stream error: \(error.localizedDescription)")
        }
    }
}
