//
//  SubscriptionView.swift
//  Diploma
//
//  Created by Orest Palii on 04.04.2025.
//

import SwiftUI

struct SubscriptionView: View {
    @StateObject private var viewModel = SubscriptionPostsViewModel()
    @State private var selectedPost: Post? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                        PostRowView(post: post)
                            .onAppear {
                                // Підвантаження, коли дійшли до кінця
                                if post == viewModel.posts.last {
                                    Task {
                                        await viewModel.loadMorePosts()
                                    }
                                }
                            }
                    }

                    if viewModel.isLoading && !viewModel.allPostsLoaded {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .task {
                await viewModel.loadInitialPosts()
            }
        }
    }
}
