import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    
    private let tagsForBack = "креативність творчість натхнення ідеї дизайн стиль фотографія мистецтво естетика концепт візуалізація колір форма текстура композиція мінімалізм експресія експеримент гармонія типографіка ілюстрація діджитал графіка абстракція архітектура футуризм вектор перспектива колаж тінь світло обʼєктив експозиція монтаж колірна палітра ретуш портрет пейзаж макро контраст інфографіка обкладинка постер брендінг айдентика моушн вебдизайн UX UI мобайл креативна ідея скетч міксмедіа анімація палітра геометрія патерн логотип емблема інтерфейс кнопка іконка неймовірне інновація технологія концепція студія редагування обʼєкт фон акцент глянець деталізація стильність настрій світловий ефект форма ритм пропорція пропущення сприйняття інтенсивність фотогенічність колірний баланс шрифт кут перспектива контент креативний стиль чіткість уява напрям текстура постобробка художність тіньовий ефект яскравість"

    var body: some View {
        NavigationView {
            ZStack {
                VStack{
                    ForEach(0..<10, id: \.self) { index in
                        MarqueeTextView(tags: tagsForBack, reverse: index % 2 == 0)
                            .frame(width: UIScreen.main.bounds.width * 2)
                            .background(index % 2 == 0 ? Color("primaryColor") : .white)
                            .foregroundStyle(index % 2 == 0 ? .white : Color("primaryColor"))
                    }
                }
                .rotationEffect(Angle(degrees: -45))
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    
                    HStack(alignment: .center){
                        Image("appLogonobackground")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 50, height: 50)
                            .padding(8)
                            .background(Color("BackgroundColor"))
                            .foregroundStyle(Color("primaryColor"))
                            .cornerRadius(20)
                        
                        Text("App Name")
                            .bold()
                            .foregroundStyle(Color("primaryColor"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(isRegistering ? "Реєстрація" : "Вхід")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(Color("primaryColor"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        TextField("Електронна пошта", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(20)

                        SecureField("Пароль", text: $password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if isRegistering && viewModel.emailVerificationSent {
                        VStack(spacing: 8) {
                            Text("На вказану пошту було надіслано лист для підтвердження.")
                                .foregroundColor(Color("primaryColor"))
                                .font(.caption)
                                .multilineTextAlignment(.center)

                            Button("Я підтвердив пошту") {
                                viewModel.checkEmailVerification()
                            }
                            .foregroundStyle(Color("primaryColor"))
                            .padding(.top, 6)
                        }
                    }

                    Button(action: {
                        if isRegistering {
                            viewModel.register(email: email, password: password)
                        } else {
                            viewModel.login(email: email, password: password)
                        }
                    }) {
                        Text(isRegistering ? "Зареєструватися" : "Увійти")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .padding(.horizontal)
                            .background(Color("primaryColor"))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }

                    Button(action: {
                        isRegistering.toggle()
                        viewModel.errorMessage = nil
                        viewModel.emailVerificationSent = false
                    }) {
                        Text(isRegistering ? "Вже маєте акаунт? Увійти" : "Немає акаунту? Зареєструватися")
                            .font(.footnote)
                            .foregroundColor(Color("primaryColor"))
                    }
                }
                .padding()
                .frame(maxWidth: 360)
                .background(.card)
                .cornerRadius(24)
                .shadow(radius: 10)
                .padding()
                .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
                     if viewModel.hasProfile {
                         ContentView()
                     } else {
                         InterestOnboardingView()
                     }
                 }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AuthView()
}
