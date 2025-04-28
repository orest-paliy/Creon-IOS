import SwiftUI
import FirebaseAuth

struct PostDetailView: View {
    let postId: String
    @StateObject private var viewModel = PostDetailViewModel()
    @State private var selectedPostForSheet: Post? = nil
    @State private var showComments = false
    @State private var showFullScreen = false
    @State private var showAuthorProfile = false
    @State private var similarPosts: [Post] = []

    var body: some View {
        Group {
            if let post = viewModel.post {
                ScrollView {
                    VStack(alignment: .leading) {
                        ZStack(alignment: .bottomTrailing) {
                            SmoothImageView(imageUrl: post.imageUrl, cornerRadius: 0)
                                .onTapGesture { showFullScreen = true }
                                .fullScreenCover(isPresented: $showFullScreen) {
                                    ZoomableImageView(imageUrl: post.imageUrl)
                                }

                            if post.isAIgenerated {
                                MarqueeTextView(tags: String(repeating: "AI generated ", count: 100), reverse: false)
                                    .foregroundStyle(.white)
                                    .padding(.bottom, 12)
                                    .background(Color("primaryColor"))
                            }

                            PostActionsView(post: post, viewModel: viewModel, showComments: $showComments, showAuthorProfile: $showAuthorProfile)
                        }

                        PostContentView(post: post)

                        Text("Схожі публікації")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top)
                            .foregroundStyle(.textPrimary)

                        PinterestGrid(posts: $similarPosts, selectedPost: $selectedPostForSheet, isItYourProfile: false)
                    }
                    .background(Color("BackgroundColor"))
                }
                .scrollIndicators(.hidden)
            } else {
                ProgressView("Завантаження публікації...")
                    .tint(Color("primaryColor"))
            }
        }
        .task {
            await viewModel.loadPost(with: postId)
            if let embedding = viewModel.post?.embedding {
                try? await UserProfileService.shared.updateUserEmbedding(with: embedding, alpha: 0.02)
                similarPosts = try! await PublicationService.shared.fetchRecommendedPosts(userEmbedding: embedding, limit: 11)
                similarPosts.removeAll(where: {$0.id == postId})
            }
        }
        .fullScreenCover(isPresented: $showComments) {
            if let post = viewModel.post {
                CommentsView(post: post)
            }
        }
        .fullScreenCover(isPresented: $showAuthorProfile) {
            if let post = viewModel.post {
                ProfileView(userId: post.authorId, onLogout: {}, selectedPost: $selectedPostForSheet)
            }
        }
        .sheet(item: $selectedPostForSheet) { newPost in
            PostDetailView(postId: newPost.id)
                .id(newPost.id)
        }
    }
}

struct PostContentView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading) {
            Text(post.title)
                .font(.title2).bold()
                .padding(.top)
                .padding(.horizontal)
                .foregroundStyle(Color("primaryColor"))

            if !post.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(post.description)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal)
            }

            Divider()

            Text("Опис зображення згенерований AI")
                .foregroundColor(.textSecondary)
                .padding(.horizontal)

            Text(post.tags)
                .padding(.leading)
                .foregroundStyle(Color("primaryColor"))
        }
        .background(Color("BackgroundColor"))
        .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct PostActionsView: View {
    let post: Post
    @ObservedObject var viewModel: PostDetailViewModel
    @Binding var showComments: Bool
    @Binding var showAuthorProfile: Bool

    var body: some View {
        HStack {
            if post.authorId != FirebaseAuth.Auth.auth().currentUser?.uid {
                Button(action: { showAuthorProfile = true }) {
                    Image(systemName: "person.crop.circle")
                        .fontWeight(.bold)
                }
                .foregroundStyle(Color("primaryColor"))
                .frame(width: 50, height: 50)
                .background(.card)
                .cornerRadius(20)
            }

            Button(action: {
                viewModel.toggleLike()
                if viewModel.isLikedByCurrentUser, let embedding = post.embedding {
                    Task {
                        try? await UserProfileService.shared.updateUserEmbedding(with: embedding, alpha: 0.1)
                    }
                }
            }) {
                Image(systemName: viewModel.isLikedByCurrentUser ? "heart.fill" : "heart")
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color("primaryColor"))
            .frame(width: 50, height: 50)
            .background(.card)
            .cornerRadius(20)

            Button(action: {
                showComments = true
                if let embedding = post.embedding {
                    Task {
                        try? await UserProfileService.shared.updateUserEmbedding(with: embedding, alpha: 0.05)
                    }
                }
            }) {
                Image(systemName: "text.bubble")
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color("primaryColor"))
            .frame(width: 50, height: 50)
            .background(.card)
            .cornerRadius(20)
            .padding(.trailing)

            AIPointerView(confidence: post.aiConfidence, scale: 0.5)
                .offset(x: -8, y: 25)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 4)
        .padding(.bottom, 16)
        .padding(.trailing, -6)
        .scaleEffect(0.9)
    }
}
