import SwiftUI

struct PostRowView: View {
    let post: Post
    @State private var imageLoaded = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                SmoothImageView(imageUrl: post.imageUrl, cornerRadius: 0).id(post.imageUrl)
            }
            .background((Color("BackgroundColor")))
            .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
            .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
            .padding(.top, 4)
            .padding(.horizontal, 4)
            .onAppear {
                loadImage(url: post.imageUrl) { success in
                    withAnimation {
                        imageLoaded = success
                    }
                }
            }

            HStack(alignment: .center){
                if !post.title.isEmpty {
                    Text(post.title)
                        .lineLimit(2)
                        .font(.subheadline)
                        .foregroundStyle(.textPrimary)
                }
                Spacer()
                if post.isAIgenerated {
                    Text("AI")
                        .font(.subheadline)
                        .cornerRadius(20)
                        .foregroundStyle(Color("primaryColor"))
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .redacted(reason: imageLoaded ? [] : .placeholder)
            
            
            HStack(spacing: 6){
                if post.likesCount > 0{
                    Label("\(post.likesCount)", systemImage: "heart.fill")
                }
                if post.comments?.count ?? 0 > 0{
                    Label("\(String(describing: post.comments!.count))", systemImage: "message.fill")
                }
            }
            .foregroundStyle(Color("primaryColor"))
            .redacted(reason: imageLoaded ? [] : .placeholder)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .padding(2)
        .background(.card)
        .cornerRadius(20)
    }

    // MARK: - Прокачане завантаження зображення для skeleton'у
    func loadImage(url: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: url) else {
            completion(false)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            completion(data != nil)
        }
        task.resume()
    }
}

struct RoundedBottomBorder: InsettableShape {
    var cornerRadius: CGFloat
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)

        let minX = insetRect.minX
        let maxX = insetRect.maxX
        let minY = insetRect.minY
        let maxY = insetRect.maxY
        let radius = cornerRadius

        path.move(to: CGPoint(x: minX, y: minY))
        path.addLine(to: CGPoint(x: minX, y: maxY - radius))
        path.addArc(center: CGPoint(x: minX + radius, y: maxY - radius),
                    radius: radius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(90),
                    clockwise: true)

        path.addLine(to: CGPoint(x: maxX - radius, y: maxY))
        path.addArc(center: CGPoint(x: maxX - radius, y: maxY - radius),
                    radius: radius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(0),
                    clockwise: true)

        path.addLine(to: CGPoint(x: maxX, y: minY))

        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

#Preview {
    PostRowView(post: Post(
        id: "",
        authorId: "",
        title: "Bla",
        description: "bla",
        imageUrl: "https://upload.wikimedia.org/wikipedia/commons/5/5a/New_building_on_Sihov_%28Lvov%29_10-2012_-_panoramio.jpg",
        isAIgenerated: true,
        aiConfidence: 30,
        tags: "dfsdf, sdfsdf,sdf dsfsdf, sdfdsf,",
        likesCount: 1,
        createdAt: Date()
    ))
}
