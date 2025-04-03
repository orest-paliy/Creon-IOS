import SwiftUI
import PhotosUI

struct CreatePostView: View {
    let authorId: String
    @Binding var didFinishPosting: Bool
    @Binding var selectedTab: TabBarViewModel.Tab
    @StateObject private var viewModel = CreatePostViewModel()
    @State private var selectedItem: PhotosPickerItem?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.title)
                                .foregroundStyle(.black)
                        }

                        Spacer()

                        Text("Створення публікації")
                            .font(.title)
                            .bold()

                        Spacer()
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ZStack {
                            if let image = viewModel.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .frame(height: 200)
                                    .overlay(Text("Виберіть зображення").foregroundColor(.gray))
                            }
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                viewModel.image = uiImage
                            }
                        }
                    }

                    TextField("Назва", text: $viewModel.title)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    TextField("Опис", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    Button("Створити публікацію") {
                        viewModel.createPost(authorId: authorId)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }

            if viewModel.isUploading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Зачекайте, поки AI обробить ваш запит…")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                }
            }
        }
        .onChange(of: viewModel.didFinishPosting) { finished in
            if finished {
                selectedTab = .home
                didFinishPosting = true
                viewModel.didFinishPosting = false
                dismiss()
            }
        }
    }
}

#Preview {
    CreatePostView(authorId: "demo",  didFinishPosting: .constant(false), selectedTab: .constant(.home))
}
