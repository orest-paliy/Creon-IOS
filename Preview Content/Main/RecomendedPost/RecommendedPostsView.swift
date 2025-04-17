//
//  RecommendedPostsView.swift
//  Diploma
//
//  Created by Orest Palii on 04.04.2025.
//

import SwiftUI

import SwiftUI

struct RecommendedPostsView: View {
    @StateObject private var recommendedVM = RecommendedPostsViewModel()
    @StateObject private var subscriptionsVM = SubscriptionPostsViewModel()

    @Binding var selectedPost: Post?

    enum PostSource {
        case recommended
        case subscriptions
    }

    @State private var selectedSource: PostSource = .recommended

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Toolbar
            HStack(spacing: 16) {
                Button(action: {
                    selectedSource = .recommended
                    Task { await recommendedVM.loadRecommendedPosts() }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: selectedSource == .recommended ? "sparkle.magnifyingglass" : "magnifyingglass")
                        Text("Рекомендовані")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(selectedSource == .recommended ? Color("primaryColor").opacity(0.2) : Color.clear)
                    .cornerRadius(10)
                }

                Button(action: {
                    selectedSource = .subscriptions
                    subscriptionsVM.loadSubscriptionPosts()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: selectedSource == .subscriptions ? "person.2.fill" : "person.2")
                        Text("Підписки")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(selectedSource == .subscriptions ? Color("primaryColor").opacity(0.2) : Color.clear)
                    .cornerRadius(10)
                }
            }
            .font(.subheadline.bold())
            .foregroundColor(Color("primaryColor"))
            .padding(.top, 12)
            .padding(.bottom, 8)
            .padding(.horizontal)
            .background(Color("BackgroundColor").ignoresSafeArea(edges: .top))
            .onChange(of: selectedSource) { newValue in
                switch newValue {
                case .recommended:
                    Task { await recommendedVM.loadRecommendedPosts() }
                case .subscriptions:
                    subscriptionsVM.loadSubscriptionPosts()
                }
            }

            // MARK: - Content
            ZStack {
                ScrollView {
                    if selectedSource == .recommended {
                        LazyVStack {
                            PinterestGrid(
                                posts: .constant(currentPosts),
                                selectedPost: $selectedPost,
                                isItYourProfile: false
                            )
                            .padding(.top)
                            .padding(.bottom, 65)
                            .animation(.easeInOut(duration: 0.3), value: currentPosts.count)
                        }
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(currentPosts, id: \.id) { item in
                                PostRowView(posts: .constant(currentPosts), post: item, isThisYourProfile: false)
                                    .onTapGesture {
                                        selectedPost = item
                                    }
                            }
                        }
                        .padding(.top)
                        .padding(.horizontal)
                        .padding(.bottom, 65)
                        .animation(.easeInOut(duration: 0.3), value: currentPosts.count)
                    }
                }
                .scrollIndicators(.hidden)

                if isLoading && currentPosts.isEmpty {
                    VStack {
                        ProgressView()
                            .tint(Color("primaryColor"))
                        Text(loadingText)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color("primaryColor"))
                    }
                    .padding()
                    .background(.card)
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            Task { await recommendedVM.loadRecommendedPosts() }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden) // <— прибираємо системний toolbar
    }

    // MARK: - Вибрані пости
    var currentPosts: [Post] {
        switch selectedSource {
        case .recommended:
            return recommendedVM.posts
        case .subscriptions:
            return subscriptionsVM.posts
        }
    }

    var isLoading: Bool {
        switch selectedSource {
        case .recommended:
            return recommendedVM.isLoading
        case .subscriptions:
            return subscriptionsVM.isLoading
        }
    }

    var loadingText: String {
        switch selectedSource {
        case .recommended:
            return "Завантажуємо ваші рекомендації..."
        case .subscriptions:
            return "Завантажуємо пости з підписок..."
        }
    }
}

#Preview {
    RecommendedPostsView(selectedPost: .constant(nil))
}
