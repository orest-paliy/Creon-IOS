import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Binding var selectedPost: Post?

    var body: some View {
        VStack {
            HStack{
                HStack {
                    TextField("Пошук за тегом...", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Пошук") {
                        viewModel.performSearch()
                    }
                    .padding(.leading, 8)
                }
                .padding()
            }

            if viewModel.isLoading {
                ProgressView().padding()
            }

            ScrollView {
                if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty && !viewModel.isLoading {
                    Text("Нічого не знайдено за вашим запитом.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    PinterestGrid(posts: viewModel.searchResults, selectedPost: $selectedPost)
                        .padding(.horizontal)
                }
            }
        }
    }
}
