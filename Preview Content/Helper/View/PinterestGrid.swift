import SwiftUI

struct PinterestGrid: View {
    let posts: [Post]
    @Binding var selectedPost: Post?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            LazyVStack(spacing: 8) {
                ForEach(posts.indices.filter { $0 % 2 == 0 }, id: \.self) { index in
                    PostRowView(post: posts[index])
                        .onTapGesture {
                            selectedPost = posts[index]
                        }
                }
            }

            LazyVStack(spacing: 8) {
                ForEach(posts.indices.filter { $0 % 2 != 0 }, id: \.self) { index in
                    PostRowView(post: posts[index])
                        .onTapGesture {
                            selectedPost = posts[index]
                        }
                }
            }
        }
        .padding(.horizontal)
    }
}
