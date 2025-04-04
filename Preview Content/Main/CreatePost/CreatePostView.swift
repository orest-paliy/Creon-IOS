import SwiftUI
import PhotosUI

struct CreatePostView: View {
    let authorId: String
    @Binding var didFinishPosting: Bool
    @Binding var selectedTab: TabBarViewModel.Tab
    @StateObject private var viewModel = CreatePostViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPromptInput = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack{
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.image == nil {
                            VStack(alignment: .leading){
                                Label("Оберіть спосіб завантаження фото", systemImage: "widget.medium")
                                    .foregroundStyle(.textSecondary)
                                HStack(spacing: 16){
                                    Button {
                                        showCamera = true
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: "camera")
                                                .font(.title2)
                                            Text("Камера")
                                                .font(.footnote)
                                        }
                                        .padding()
                                        .frame(height: 80)
                                        .frame(maxWidth: .infinity)
                                        .background(.card)
                                        .foregroundStyle(Color("primaryColor"))
                                        .cornerRadius(20)
                                    }
                                    
                                    PhotosPicker(selection: $selectedItem, matching: .images) {
                                        VStack(spacing: 6) {
                                            Image(systemName: "photo")
                                                .font(.title2)
                                            Text("Галерея")
                                                .font(.footnote)
                                        }
                                        .padding()
                                        .frame(height: 80)
                                        .frame(maxWidth: .infinity)
                                        .background(.card)
                                        .foregroundStyle(Color("primaryColor"))
                                        .cornerRadius(20)
                                    }

                                    Button {
                                        showPromptInput = true
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: "sparkles")
                                                .font(.title2)
                                            Text("AI")
                                                .font(.footnote)
                                        }
                                        .padding()
                                        .frame(height: 80)
                                        .frame(maxWidth: .infinity)
                                        .background(.card)
                                        .foregroundStyle(Color("primaryColor"))
                                        .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.top)
                        }

                        // MARK: - Prompt Input
                        if showPromptInput && viewModel.image == nil {
                            VStack(spacing: 12) {
                                TextField("Введіть промпт для генерації зображення", text: $viewModel.prompt, axis: .vertical)
                                    .padding()
                                    .background(.card)
                                    .cornerRadius(20)

                                Button("Згенерувати зображення") {
                                    viewModel.generateImageFromPrompt()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("primaryColor"))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                        }

                        // MARK: - Image Preview
                        if let image = viewModel.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                        }

                        // MARK: - Title & Description
                        if viewModel.image != nil {
                            VStack(spacing: 16) {
                                TextField("Назва", text: $viewModel.title)
                                    .padding()
                                    .background(.card)
                                    .cornerRadius(20)

                                TextField("Опис", text: $viewModel.description, axis: .vertical)
                                    .lineLimit(3...6)
                                    .padding()
                                    .background(.card)
                                    .cornerRadius(20)
                            }

                            // MARK: - Error
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }

                            // MARK: - Create Post Button
                            Button("Створити публікацію") {
                                viewModel.createPost(authorId: authorId)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("primaryColor"))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                    .padding()
                }

                // MARK: - Loader
                if viewModel.isUploading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)

                            Text("Зачекайте, поки AI обробить ваш запит…")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                }
            }
            .navigationTitle("Створення публікації")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                        }
                        .foregroundStyle(Color("primaryColor"))
                    }
                }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    viewModel.image = uiImage
                    showPromptInput = false
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $viewModel.image)
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
    CreatePostView(authorId: "", didFinishPosting: .constant(false), selectedTab: .constant(.create))
}
