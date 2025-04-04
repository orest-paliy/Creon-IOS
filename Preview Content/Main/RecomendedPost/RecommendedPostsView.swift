//
//  RecommendedPostsView.swift
//  Diploma
//
//  Created by Orest Palii on 04.04.2025.
//

import SwiftUI

struct RecommendedPostsView: View {
    @StateObject private var viewModel = RecommendedPostsViewModel()
    @Binding var selectedPost: Post?

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack {
                    PinterestGrid(posts: viewModel.posts, selectedPost: $selectedPost)
                        .padding(.top)
                        .padding(.bottom, 65)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
                }
            }
            .scrollIndicators(.hidden)

            if viewModel.isLoading && viewModel.posts.isEmpty {
                VStack {
                    ProgressView()
                        .tint(Color("primaryColor"))
                    Text("Завантажуємо ваші рекомендації...")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color("primaryColor"))
                }
                .padding()
                .background(.card)
                .cornerRadius(20)
                .padding(.horizontal)
            }
        }
        .task {
            await viewModel.loadRecommendedPosts()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle.magnifyingglass")
                    Text("Рекомендації")
                        .font(.headline)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitleDisplayMode(.inline)
    }
}
