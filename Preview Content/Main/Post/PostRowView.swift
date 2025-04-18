import SwiftUI
import FirebaseAuth

struct PostRowView: View {
    @Binding var posts: [Post]
    let post: Post
    let isThisYourProfile: Bool
    @State private var imageLoaded = false
    @State private var showDeleteAlert = false
    @State private var showNotInterestedToast = false

    private var isInfoStackIsEmpty: Bool {
        return post.title.isEmpty &&
        !post.isAIgenerated &&
        !isThisYourProfile &&
        post.likesCount == 0 &&
        post.comments?.count ?? 0 == 0
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    SmoothImageView(imageUrl: post.imageUrl, cornerRadius: 0).id(post.imageUrl)
                        .background(Color("BackgroundColor"))
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

                    if !isThisYourProfile {
                        Menu {
                            Button {
                                PublicationService.shared.saveImageToGallery(from: post.imageUrl)
                            } label: {
                                Label("Завантажити зображення", systemImage: "arrow.down.to.line")
                            }.foregroundStyle(Color("primaryColor"))
                            
                            Button("Мене не цікавить такий контент", role: .destructive) {
                                handleNotInterested()
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.degrees(90))
                                .foregroundColor(Color("primaryColor"))
                                .padding(12)
                                .padding(.top, 6)
                                .background(Color.clear)
                                .contentShape(Rectangle())
                                .frame(width: 60, height: 60, alignment: .topTrailing)
                        }
                    }
                }

                HStack(alignment: .center) {
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

                    if isThisYourProfile {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .alert("Ви дійсно хочете видалити публікацію?", isPresented: $showDeleteAlert) {
                            Button("Видалити", role: .destructive) {
                                deletePost()
                            }
                            Button("Скасувати", role: .cancel) { }
                        }
                    }
                }
                .padding(.vertical, isInfoStackIsEmpty ? 0 : 4)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .redacted(reason: imageLoaded ? [] : .placeholder)

                HStack(spacing: 6) {
                    if post.likesCount > 0 {
                        Label("\(post.likesCount)", systemImage: "heart.fill")
                    }
                    if post.comments?.count ?? 0 > 0 {
                        Label("\(post.comments!.count)", systemImage: "message.fill")
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

            if showNotInterestedToast {
                Color.black.opacity(0.7)
                    .cornerRadius(20)
                    .overlay(
                        VStack {
                            Text("Ми намагатимемось уникати подібного контенту")
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: showNotInterestedToast)
            }
        }
    }

    func handleNotInterested() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        UserProfileService.shared.updateUserEmbedding(
            uid: uid,
            postEmbedding: post.embedding!.map { Float($0) },
            alpha: 0.05,
            direction: "away"
        ) { result in
            DispatchQueue.main.async {
                withAnimation {
                    showNotInterestedToast = true
                }
            }
        }
    }

    func loadImage(url: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: url) else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            completion(data != nil)
        }.resume()
    }

    func deletePost() {
        PublicationService.shared.deletePost(id: post.id) { error in
            if let error = error {
                print("Не вдалося видалити публікацію:", error.localizedDescription)
            } else {
                posts.removeAll(where: { $0.id == post.id })
                print("Публікацію успішно видалено")
            }
        }
    }
}
