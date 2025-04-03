import SwiftUI
import FirebaseAuth

struct InterestOnboardingView: View {
    @State private var selectedTags: Set<String> = []
    @State private var isLoading = false
    @State private var navigateToHome = false

    let tags: [String] = [
        "Графічний дизайн", "Ілюстрація", "Цифрове мистецтво", "Образотворче мистецтво", "Живопис", "Акварель", "Шрифт", "Типографіка", "Колажі", "Скрапбукінг", "Плакатний дизайн", "Брендинг", "Логотипи", "UI-дизайн", "3D-дизайн",
        
        "Інтерʼєр", "Дизайн кімнат", "Мінімалізм", "Максималізм", "Архітектура", "Модерн", "Скандинавський стиль", "Бохо", "Організація простору", "Поради по декору", "Кольорові палітри", "Текстури й матеріали",

        "Мода", "Макіяж", "Бʼюті", "Модні образи", "Нейл-дизайн", "Фешн ідеї", "Стілінг", "Аксесуари", "Тренди",

        "DIY-проєкти", "Рукоділля", "Кераміка", "Флористика", "Планери", "Розклад на тиждень", "Листівки", "Миловаріння", "Свічки своїми руками",

        "Стиль життя", "Подорожі", "Рецепти", "Фотографія", "Ранкові ритуали", "Музика настрою", "Здоровʼя", "Естетика дня", "Декор до свят",

        "UX/UI", "Айдентика", "Креативне мислення", "Мистецька освіта", "Історія мистецтва", "Дизайн-мислення",

        "Садівництво", "Психологія", "Екологія", "Сімейний затишок", "Хюґе", "Арттерапія"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .leading){
                    Text("Оберіть свої інтереси")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimary)
                        .padding(.horizontal)
                    
                    Text("Отримуйте кращі рекомендації")
                        .foregroundStyle(.textSecondary)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            let rows = tags.chunked(into: 3)
                            ForEach(0..<rows.count, id: \.self) { rowIndex in
                                HStack(spacing: 10) {
                                    ForEach(rows[rowIndex], id: \.self) { tag in
                                        Button(action: {
                                            if selectedTags.contains(tag) {
                                                selectedTags.remove(tag)
                                            } else {
                                                selectedTags.insert(tag)
                                            }
                                        }) {
                                            Text(tag)
                                                .lineLimit(1)
                                                .font(.caption)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 14)
                                                .background(selectedTags.contains(tag) ? Color("primaryColor") : .card)
                                                .foregroundColor(selectedTags.contains(tag) ? .white : Color("TextPrimary"))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .scrollIndicators(.hidden)
                }
                
                VStack {
                    Spacer()
                    if !selectedTags.isEmpty{
                        Button("Продовжити") {
                            startProfileSetup()
                        }
                        .disabled(selectedTags.isEmpty)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("primaryColor"))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .padding()
                    }
                }
            }
            .overlay(content: {
                if isLoading{
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(Color("primaryColor"))
                        Text("Налаштовуємо стрічку під ваші інтереси та створюємо унікальний аватар")
                            .font(.headline)
                            .foregroundColor(Color("primaryColor"))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(0)
                    .ignoresSafeArea()
                }
            })
            .fullScreenCover(isPresented: $navigateToHome) {
                ContentView()
            }
        }
    }

    func startProfileSetup() {
        isLoading = true

        let tagsList = Array(selectedTags)
        let prompt = "Користувач обрав інтереси: \(tagsList.joined(separator: ", ")). Сформуй короткий опис його стилю."
        let gptService = GPTTagService()
        gptService.generateEmbedding(from: prompt) { embedding in
            guard !embedding.isEmpty else { return }

            gptService.generateAvatarImageBase64(from: tagsList) { image in
                guard let avatar = image else { return }

                let email = Auth.auth().currentUser?.email ?? ""
                UserProfileService.shared.createUserProfile(email: email, interests: tagsList, avatarImage: avatar, embedding: embedding) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        navigateToHome = true
                    }
                }
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}


#Preview {
    InterestOnboardingView()
}
