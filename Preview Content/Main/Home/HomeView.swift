import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Binding var selectedPost: Post?

    var body: some View {
        ZStack(alignment: .top){
            ScrollView {
                LazyVStack {
                    PinterestGrid(posts: viewModel.posts, selectedPost: $selectedPost)
                        .padding(.top, viewModel.isLoading ? 160 : 40)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)

                    
                    if viewModel.isLoading {
                        ProgressView().padding()
                    } else if !viewModel.isSearching {
                        Button("Завантажити ще...") {
                            Task {
                                await viewModel.loadMorePosts()
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Color("primaryColor"))
                        .padding()
                        .padding(.bottom, 50)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.top, 40)
            
            
            VStack{
                HStack {
                    TextField("Пошуковий запит", text: $viewModel.searchQuery)
                        .padding(.leading)
                        .onChange(of: viewModel.searchQuery) { newValue in
                            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                viewModel.clearSearch()
                            }
                        }

                    HStack{
                        Button(action: {
                            viewModel.performSearch()
                        }, label: {
                            Image(systemName: "magnifyingglass")
                                .padding(12)
                                .background(Color("primaryColor"))
                                .cornerRadius(45)
                                .foregroundStyle(Color("BackgroundColor"))
                        })
                        if !viewModel.searchQuery.isEmpty{
                            Button(action: {
                                viewModel.clearSearch()
                            }, label: {
                                Image(systemName: "xmark")
                                    .padding(12)
                                    .background(Color("BackgroundColor"))
                                    .cornerRadius(45)
                                    .foregroundStyle(Color("primaryColor"))
                            })
                        }
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(45)
                .padding()
                
                if !viewModel.searchQuery.isEmpty && viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .tint(Color("primaryColor"))
                        Text("Зачекайте, будь ласка, ми обробляємо ваш запит")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color("primaryColor"))
                    }
                    .padding()
                    .background(.card)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.top, -10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if !viewModel.isLoading && viewModel.posts.count == 0{
                    Text("Нажаль нам не вдалось завантажити нічого за вашим запитом")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color("primaryColor"))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: viewModel.isLoading)
        }
        .task {
            await viewModel.loadInitialPosts()
        }
    }
}

#Preview {
    HomeView(selectedPost: .constant(nil))
}
