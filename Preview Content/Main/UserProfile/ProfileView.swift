import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    var onLogout: () -> Void
    @Environment(\.dismiss) var dismiss
    @Binding var selectedPost: Post?
    @State private var showLogoutAlert = false
    @State private var selectedPostForSheet: Post? = nil

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
                        } else {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color("primaryColor"))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        Text(viewModel.userEmail)
                            .foregroundStyle(Color("primaryColor"))
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
                            .cornerRadius(12)
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
                        Label("Створені", systemImage: "folder.badge.plus")
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
                            Label("Вподобані", systemImage: "heart")
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(viewModel.selectedTab == .liked ? Color("primaryColor").opacity(0.2) : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                }
                .font(.subheadline.bold())
                .foregroundColor(Color("primaryColor"))

                if viewModel.posts.isEmpty {
                    Spacer()
                    Text("Немає публікацій")
                        .foregroundColor(.textSecondary)
                    Spacer()
                } else {
                    ScrollView {
                        PinterestGrid(posts: viewModel.posts, selectedPost: $selectedPostForSheet)
                            .padding(.top, 8)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .task {
                await viewModel.fetchUserData()
            }
            .sheet(item: $selectedPostForSheet) { newPost in
                PostDetailView(post: .constant(newPost))
            }
        }
    }
    
    
}

#Preview {
    ProfileView(userId: "YVAVUZTiJgVf8N4iSLZ1NuyFprz1", onLogout: {}, selectedPost: .constant(nil))
}
