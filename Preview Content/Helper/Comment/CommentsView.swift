import SwiftUI

struct CommentsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CommentsViewModel

    init(post: Post) {
        _viewModel = StateObject(wrappedValue: CommentsViewModel(postId: post.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.comments) { comment in
                        CommentRowView(
                            comment: comment,
                            onLikeTapped: {
                                Task {
                                    await viewModel.toggleLike(for: comment.id)
                                }
                            },
                            isLiked: comment.likedBy?.contains(viewModel.currentUserId) ?? false
                        )
                        .padding(.horizontal)
                    }
                }
            }

            Divider()

            inputField
        }
        .background(Color("BackgroundColor"))
        .onAppear {
            Task { await viewModel.fetchComments() }
        }
    }

    private var header: some View {
        VStack {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(Color("primaryColor"))
                }

                Text("Коментарі")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()
            }
            .padding(.horizontal)

            Divider()
        }
    }

    private var inputField: some View {
        HStack {
            TextField("Ваш коментар...", text: $viewModel.newComment)
                .padding(10)
                .background(.card)
                .cornerRadius(20)

            Button {
                Task { await viewModel.addComment() }
            } label: {
                Image(systemName: "paperplane")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color("primaryColor"))
                    .clipShape(Circle())
            }
            .disabled(viewModel.newComment.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
        .background(Color("BackgroundColor"))
    }
}
