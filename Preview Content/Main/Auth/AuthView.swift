import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 12) {
                    
                    HStack(alignment: .center){
                        Image("appLogoWhite")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 60, height: 60)
                            .padding(8)
                            .background(Color("BackgroundColor"))
                            .foregroundStyle(Color("primaryColor"))
                            .cornerRadius(20)
                        
                        Text(isRegistering ? "Реєстрація" : "Вхід")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(Color("primaryColor"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                            TextField("Електронна пошта", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(20)

                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                            Group {
                                if isPasswordVisible {
                                    TextField("Пароль", text: $password)
                                } else {
                                    SecureField("Пароль", text: $password)
                                }
                            }
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
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
