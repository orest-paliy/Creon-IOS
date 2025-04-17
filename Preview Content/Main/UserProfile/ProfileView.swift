import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    var onLogout: () -> Void
    @Environment(\.dismiss) var dismiss
    @Binding var selectedPost: Post?
    @State private var showLogoutAlert = false
    @State private var selectedPostForSheet: Post? = nil
    @State private var showFullScreen: Bool = false

    init(userId: String? = nil, onLogout: @escaping () -> Void, selectedPost: Binding<Post?>) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
        self.onLogout = onLogout
        self._selectedPost = selectedPost
    }

    var body: some View {
        NavigationStack {
            VStack {
                if !viewModel.isCurrentUser {
                    Button("Назад") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    .foregroundStyle(Color("primaryColor"))
                }

                VStack(alignment: .center, spacing: 12) {
                    HStack(alignment: .center) {
                        if let image = viewModel.avatarImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .onTapGesture {
                                    showFullScreen = true
                                }
                                .fullScreenCover(isPresented: $showFullScreen) {
                                    ZoomableImageView(imageUrl: viewModel.avatarURL)
                                }
                        } else {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color("primaryColor"))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        VStack(alignment: .leading){
                            Text(viewModel.userEmail)
                                .foregroundStyle(Color("primaryColor"))
                            HStack{
                                VStack {
                                    Text("\(viewModel.posts.count)")
                                        .font(.headline)
                                    Text("Публікацій")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                VStack {
                                     Text("\(viewModel.followersCount)")
                                         .font(.headline)
                                     Text("Підписників")
                                         .font(.caption)
                                         .foregroundStyle(.secondary)
                                 }

                                 VStack {
                                     Text("\(viewModel.subscriptionsCount)")
                                         .font(.headline)
                                     Text("Підписок")
                                         .font(.caption)
                                         .foregroundStyle(.secondary)
                                 }
                            }
                        }.redacted(reason: viewModel.avatarImage == nil ? .placeholder : [])
                    }

                    if viewModel.isCurrentUser {
                        Button {
                            showLogoutAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.slash")
                                Text("Вийти з акаунту")
                            }
                            .foregroundColor(Color("primaryColor"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color("primaryColor").opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    else {
                        Button(action: {
                            viewModel.toggleSubscription()
                        }) {
                            Text(viewModel.isSubscribed ? "Відписатись" : "Підписатись")
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(viewModel.isSubscribed ? Color.red : Color("primaryColor"))
                                .cornerRadius(10)
                        }
                    }

                    
                }
                .padding(12)
                .background(.card)
                .cornerRadius(20)
                .padding(.top)
                .alert("Вийти з акаунту?", isPresented: $showLogoutAlert) {
                    Button("Вийти", role: .destructive) {
                        viewModel.logout()
                    }
                    Button("Скасувати", role: .cancel) {}
                }
                
                Text("Інтереси користувача")
                    .foregroundStyle(Color("primaryColor"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                
                if let interests = viewModel.userProfile?.interests {
                    let screenWidth = UIScreen.main.bounds.width - 32
                    let rows = viewModel.chunkTagsToRows(tags: interests, maxWidth: screenWidth, font: UIFont.preferredFont(forTextStyle: .callout))

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(rows, id: \.self) { row in
                            HStack(spacing: 10) {
                                ForEach(row, id: \.self) { tag in
                                    Text(tag)
                                        .font(.callout)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 14)
                                        .background(.card)
                                        .foregroundColor(.textSecondary)
                                        .clipShape(Capsule())
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                }



                Divider().padding(.vertical, 12)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.selectedTab = .created
                        Task { await viewModel.fetchUserData() }
                    }) {
                        Label("Створені", systemImage: viewModel.selectedTab == .created ? "folder.fill.badge.plus" : "folder.badge.plus")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(viewModel.selectedTab == .created ? Color("primaryColor").opacity(0.2) : Color.clear)
                            .cornerRadius(10)
                    }

                    if viewModel.isCurrentUser {
                        Button(action: {
                            viewModel.selectedTab = .liked
                            Task { await viewModel.fetchUserData() }
                        }) {
                            Label("Вподобані", systemImage: viewModel.selectedTab == .liked ? "heart.fill" : "heart")
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(viewModel.selectedTab == .liked ? Color("primaryColor").opacity(0.2) : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                }
                .font(.subheadline.bold())
                .foregroundColor(Color("primaryColor"))

                if viewModel.isLoading && viewModel.posts.isEmpty {
                    VStack {
                        ProgressView()
                            .tint(Color("primaryColor"))
                        Text("Зачекайте, дані користувача завантажуються...")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color("primaryColor"))
                    }
                    .padding()
                    .background(.card)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.top, 60)
                    Spacer()
                }
                else if viewModel.posts.isEmpty {
                    Spacer()
                    Text("Немає публікацій")
                        .foregroundColor(.textSecondary)
                    Spacer()
                } else {
                    ScrollView {
                        PinterestGrid(posts: $viewModel.posts, selectedPost: $selectedPostForSheet, isItYourProfile: true)
                            .padding(.top, 8)
                            .padding(.bottom, 60)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .task {
                await viewModel.fetchUserData()
                viewModel.checkSubscriptionStatus()
                viewModel.fetchFollowersCount()
                viewModel.fetchSubscriptionsCount()
            }
            .sheet(item: $selectedPostForSheet) { newPost in
                PostDetailView(postId: newPost.id)
            }
        }
    }
    
    
}

#Preview {
    ProfileView(userId: "YVAVUZTiJgVf8N4iSLZ1NuyFprz1", onLogout: {}, selectedPost: .constant(nil))
}
