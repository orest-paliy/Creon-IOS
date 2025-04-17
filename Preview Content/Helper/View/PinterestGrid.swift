import SwiftUI

struct PinterestGrid: View {
    @Binding var posts: [Post]
    @Binding var selectedPost: Post?
    @State var isItYourProfile: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            LazyVStack(spacing: 8) {
                ForEach(posts.indices.filter { $0 % 2 == 0 }, id: \.self) { index in
                    PostRowView(posts : $posts, post: posts[index], isThisYourProfile : isItYourProfile)
                        .onTapGesture {
                            selectedPost = posts[index]
                        }
                }
            }

            LazyVStack(spacing: 8) {
                ForEach(posts.indices.filter { $0 % 2 != 0 }, id: \.self) { index in
                    PostRowView(posts : $posts, post: posts[index], isThisYourProfile : isItYourProfile)
                        .onTapGesture {
                            selectedPost = posts[index]
                        }
                }
            }
        }
        .padding(.horizontal)
    }
}
