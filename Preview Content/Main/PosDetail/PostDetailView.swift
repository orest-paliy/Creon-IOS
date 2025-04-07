import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct PostDetailView: View {
    @Binding var post: Post
    @StateObject private var viewModel: PostDetailViewModel
    @State private var similarPosts: [Post] = []
    @State private var showComments = false
    @State var selectedPostForSheet: Post?
    @State private var showFullScreen = false
    @State private var showAuthorProfile = false

    
    var AItext: String {
        let ai = "AI generated "
        var result = ""
        for _ in 0...100{
            result += ai
        }
        return result
    }

    init(post: Binding<Post>) {
        self._post = post
        self._viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post.wrappedValue))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ZStack(alignment: .bottomTrailing) {
                    SmoothImageView(imageUrl: viewModel.post.imageUrl, cornerRadius: 0)
                        .onTapGesture {
                            showFullScreen = true
                        }
                        .fullScreenCover(isPresented: $showFullScreen) {
                            ZoomableImageView(imageUrl: viewModel.post.imageUrl)
                        }
                    
                    if post.isAIgenerated{
                        MarqueeTextView(tags: AItext, reverse: false)
                            .foregroundStyle(.white)
                            .padding(.bottom, 12)
                            .background(Color("primaryColor"))
                    }
                    
                    HStack {
                        if post.authorId != FirebaseAuth.Auth.auth().currentUser?.uid {
                            Button(action: {
                                showAuthorProfile = true
                            }) {
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
                            post = viewModel.post
                            if viewModel.isLikedByCurrentUser{
                                Task {
                                    if let embedding = viewModel.post.embedding {
                                        try await UserProfileService.shared.updateUserEmbedding(with: embedding, alpha: 0.1)
                                    }
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
                        
                        Button {
                            showComments = true
                            Task {
                                if let embedding = viewModel.post.embedding {
                                    try await UserProfileService.shared.updateUserEmbedding(with: embedding, alpha: 0.05)
                                }
                            }
                        } label: {
                            Image(systemName: "text.bubble")
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(Color("primaryColor"))
                        .frame(width: 50, height: 50)
                        .background(.card)
                        .cornerRadius(20)
                        .padding(.trailing)
                        
                        AIPointerView(confidence: viewModel.post.aiConfidence, scale: 0.5)
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
                
                VStack(alignment: .leading) {
                    Text(viewModel.post.title)
                        .font(.title2).bold()
                        .padding(.top)
                        .padding(.horizontal)
                        .foregroundStyle(Color("primaryColor"))
                    
                    if !viewModel.post.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(viewModel.post.description)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    Text("Опис зображення згенерований AI")
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal)
                    
                    Text(viewModel.post.tags)
                        .padding(.leading)
                        .foregroundStyle(Color("primaryColor"))
                
                    
                    Text("Схожі публікації")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                        .foregroundStyle(.textPrimary)
                    
                    PinterestGrid(posts: similarPosts, selectedPost: $selectedPostForSheet)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("BackgroundColor"))
                .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
                .offset(y: -20)
                .ignoresSafeArea(.container)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear {
            viewModel.fetchPostFromFirebase()
            Task {
                await loadSimilarPosts()
                
                //MARK: оновлення embedding вектора
                if let embedding = viewModel.post.embedding {
                    try await UserProfileService.shared.updateUserEmbedding(with: embedding, alpha: 0.02)
                }
            }
        }
        .fullScreenCover(isPresented: $showComments) {
            CommentsView(post: viewModel.post)
        }
        .fullScreenCover(isPresented: $showAuthorProfile) {
            ProfileView(userId: viewModel.post.authorId, onLogout: {}, selectedPost: $selectedPostForSheet)
        }
        .sheet(item: $selectedPostForSheet) { newPost in
            PostDetailView(post: .constant(newPost))
        }
    }
    private func loadSimilarPosts() async {
        do{
            self.similarPosts = try await PublicationService.shared.fetchRecommendedPosts(userEmbedding: post.embedding ?? [], limit: 10)
        }catch{}
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


#Preview {
    PostDetailView(
        post: .constant(
            Post(
                id: "2",
                authorId: "user234",
                title: "Модернова будівля",
                description: "Інший кут огляду на сучасну архітектуру.",
                imageUrl: "https://play-lh.googleusercontent.com/pLgcGXB-pJxBv4L0xzpXsRE-exMHG_M7jOdYWPsZUoQ-OW4WLO-Pz6GmtomDZN7fkmg=w240-h480-rw",
                isAIgenerated: false,
                aiConfidence: 25,
                tags: "building, design, architecture",
                comments: [],
                likesCount: 8,
                createdAt: Date(),
                updatedAt: nil
            )
        )
    )
}


