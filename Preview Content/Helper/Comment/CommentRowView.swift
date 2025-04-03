import SwiftUI

struct CommentRowView: View {
    let comment: Comment
    let onLikeTapped: () -> Void
    let isLiked: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.purple.opacity(0.8))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Користувач: \(comment.userId.prefix(10))...")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    Text(comment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Text(comment.text)
                    .font(.body)
                    .padding(10)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)

                HStack {
                    Button(action: onLikeTapped) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .purple : .gray)
                    }

                    Text("\(comment.likedBy?.count ?? 0)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    CommentRowView(comment: Comment(id: "", userId: "", text: "", createdAt: Date.now), onLikeTapped: {}, isLiked: true)
}
