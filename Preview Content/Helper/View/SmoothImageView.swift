import SwiftUI

struct SmoothImageView: View {
    let imageUrl: String
    let cornerRadius: CGFloat

    @State private var uiImage: UIImage? = nil
    @State private var targetHeight: CGFloat = 150
    @State private var isImageLoaded = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 🔲 Завантажене зображення
                if let image = uiImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: targetHeight)
                        .clipped()
                        .clipShape(RoundedCorner(radius: cornerRadius, corners: [.topLeft, .topRight]))
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0), value: isImageLoaded)
                        .background((Color("BackgroundColor"))  )
                }

                if !isImageLoaded {
                    placeholder
                        .frame(width: geo.size.width, height: targetHeight)
                        .transition(.opacity)
                }
            }
            .onAppear {
                loadImage(from: imageUrl, width: geo.size.width)
            }
        }
        .frame(height: targetHeight)
    }

    var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color("BackgroundColor"))
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("primaryColor")))
            )
            .clipShape(RoundedCorner(radius: cornerRadius, corners: [.topLeft, .topRight]))
    }

    private func loadImage(from urlString: String, width: CGFloat) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let image = UIImage(data: data) else { return }

            let ratio = image.size.height / image.size.width
            let calculatedHeight = width * ratio

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.uiImage = image
                    self.targetHeight = calculatedHeight
                    self.isImageLoaded = true
                }
            }
        }.resume()
    }
}
