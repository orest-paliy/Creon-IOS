import SwiftUI
import FirebaseAuth

struct InterestOnboardingView: View {
    @State private var selectedTags: Set<String> = []
    @State private var isLoading = false
    @State private var navigateToHome = false

    let tags: [String] = [
        // Дизайн та візуальні комунікації
        "Графічний дизайн", "Плакатний дизайн", "Брендинг", "Логотипи", "Айдентика", "UI-дизайн", "UX-дизайн", "Вебдизайн", "Мобільний дизайн", "Інтерфейси", "3D-дизайн", "Анімація", "Моушн-дизайн", "Інфографіка",
        
        //Дизайн середовища
        "Інтерʼєр", "Архітектура", "Дизайн кімнат", "Ландшафтний дизайн", "Декорування", "Текстури й матеріали", "Кольорові палітри", "Організація простору", "Стилі інтерʼєру", "Мінімалізм", "Максималізм", "Скандинавський стиль", "Бохо", "Еко-дизайн",
        
        //Фото та відео
        "Фотографія", "Портретна зйомка", "Пейзажі", "Стріт-фото", "Аналогова фотографія", "Фільмова естетика", "Фотоколаж", "Відеографія", "Кінематографічне відео", "Кольорокорекція",

        //Ілюстрація та цифрове мистецтво
        "Ілюстрація", "Цифрове мистецтво", "Концепт-арт", "Комікси", "Векторна графіка", "3D-арт", "Піксель-арт", "Ретуш", "Фан-арт", "Малювання на планшеті",

        //Образотворче мистецтво
        "Живопис", "Масло", "Акрил", "Акварель", "Гуаш", "Пастель", "Графіка", "Каліграфія", "Шрифт", "Типографіка", "Іконопис", "Монотипія", "Гравюра",

        //Традиційні техніки та ремесла
        "Кераміка", "Гончарство", "Скульптура", "Ліплення", "Ткацтво", "Вишивка", "В'язання", "Шиття", "Миловаріння", "Свічки ручної роботи", "Флористика", "Натуральне фарбування", "Батик",

        // Креативність та освіта
        "Креативне мислення", "Дизайн-мислення", "Мистецька освіта", "Історія мистецтва", "Культурологія", "Психологія творчості", "Арттерапія",
        
        // Мода та стиль
        "Мода", "Стілінг", "Тренди", "Макіяж", "Нейл-дизайн", "Бʼюті", "Аксесуари", "Фешн-ідеї", "Одяг своїми руками", "Етична мода", "Апсайклінг",

        // DIY та хендмейд
        "DIY-проєкти", "Рукоділля", "Листівки", "Скрапбукінг", "Планери", "Розклад на тиждень", "Органайзери", "Декор до свят", "Хендмейд подарунки", "Хобі", "Мініатюри", "Моделювання",

        // Стиль життя та натхнення
        "Стиль життя", "Подорожі", "Здоровʼя", "Хюґе", "Сімейний затишок", "Ранкові ритуали", "Музика настрою", "Садівництво", "Екологія", "Устойчиве життя", "Вегетаріанські рецепти", "Естетика дня", "Продуктивність",

        // Технології та експерименти
        "AI-арт", "Генеративне мистецтво", "Код-арт", "Інтерактивний дизайн", "AR/VR", "Медіа-арт", "Мистецтво й технології"
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
        let gptService = ChatGPTService()
        gptService.generateEmbedding(from: prompt) { embedding in
            guard !embedding.isEmpty else { return }

            gptService.generateImageBase64(fromTags: tagsList) { image in
                guard let avatar = image else { return }

                let email = Auth.auth().currentUser?.email ?? ""
                UserProfileService.shared.uploadAvatarImage(avatar, uid: email) { result in
                    switch result {
                    case .success(let avatarURL):
                        UserProfileService.shared.createUserProfile(
                            email: email,
                            interests: tagsList,
                            avatarURL: avatarURL,
                            embedding: embedding,
                            subscriptions: [],
                            followers: []
                        ) { result in
                            DispatchQueue.main.async {
                                isLoading = false
                                navigateToHome = true
                            }
                        }
                    case .failure(let error):
                        print("Failed to upload avatar:", error)
                        isLoading = false
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
