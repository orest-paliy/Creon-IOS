import Foundation
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage: String?
    @Published var emailVerificationSent = false
    @Published var isEmailVerified = false
    @Published var hasProfile: Bool = false

    init() {
        checkSession()
    }

    func checkSession() {
        if let user = Auth.auth().currentUser {
            user.reload { error in
                if user.isEmailVerified {
                    self.checkIfProfileExists()
                } else {
                    DispatchQueue.main.async {
                        self.isLoggedIn = false
                        self.emailVerificationSent = true
                    }
                }
            }
        }
    }

    func register(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = self.localizedError(error)
                return
            }

            result?.user.sendEmailVerification { error in
                if let error = error {
                    self.errorMessage = "Помилка при надсиланні листа: \(error.localizedDescription)"
                } else {
                    DispatchQueue.main.async {
                        self.emailVerificationSent = true
                    }
                }
            }
        }
    }

    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = self.localizedError(error)
                return
            }

            self.checkEmailVerification()
        }
    }
//
    func checkEmailVerification() {
        Auth.auth().currentUser?.reload(completion: { error in
            if let error = error {
                self.errorMessage = self.localizedError(error)
                return
            }

            if let user = Auth.auth().currentUser, user.isEmailVerified {
                self.isEmailVerified = true
                self.checkIfProfileExists()
            } else {
                self.errorMessage = "Будь ласка, підтвердіть свою електронну пошту, перш ніж продовжити."
            }
        })
    }

    func checkIfProfileExists() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        UserProfileService.shared.checkIfUserProfileExists(uid: uid) { exists in
            DispatchQueue.main.async {
                self.hasProfile = exists
                self.isLoggedIn = true
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
            self.isEmailVerified = false
            self.hasProfile = false
        } catch {
            self.errorMessage = "Не вдалося вийти з акаунту: \(error.localizedDescription)"
        }
    }

    private func localizedError(_ error: Error) -> String {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        switch code {
        case .invalidEmail:
            return "Неправильний формат електронної пошти."
        case .emailAlreadyInUse:
            return "Ця електронна пошта вже зареєстрована."
        case .weakPassword:
            return "Пароль надто слабкий. Використайте щонайменше 6 символів."
        case .wrongPassword:
            return "Неправильний пароль."
        case .userNotFound:
            return "Користувача з такою електронною поштою не знайдено."
        default:
            return "Помилка: \(error.localizedDescription)"
        }
    }
}
