import SwiftUI
import FirebaseStorage
import UIKit

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userEmail: String = ""
    @Published var posts: [Post] = []
    @Published var errorMessage: String?
    @Published var isLoggedOut = false
    @Published var selectedTab: ProfilePostTab = .created
    @Published var avatarImage: UIImage? = nil
    @Published var isCurrentUser: Bool = true
    @Published var avatarURL: String = ""
    @Published var userProfile: UserProfileDTO? = nil

    var userId: String?

    init(userId: String? = nil) {
        self.userId = userId ?? FirebaseUserService.shared.currentUserId
        self.isCurrentUser = self.userId == FirebaseUserService.shared.currentUserId
    }

    func fetchUserData() async {
        guard let uid = userId else { return }

        do {
            let profile = try await FirebaseUserService.shared.fetchUserProfile(uid: uid)
            self.userProfile = profile
            self.userEmail = profile.email
            self.avatarURL = profile.avatarURL
            self.avatarImage = try await loadImageFromURL(avatarURL)

            switch selectedTab {
            case .created:
                posts = try await FirebasePostService.shared.fetchUserPosts(userId: uid)
            case .liked:
                if isCurrentUser {
                    posts = try await FirebasePostService.shared.fetchLikedPosts(for: uid)
                } else {
                    posts = []
                }
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func loadImageFromURL(_ urlString: String?) async throws -> UIImage? {
        guard let urlString = urlString, let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    }

    func logout() {
        do {
            try FirebaseUserService.shared.logout()
            isLoggedOut = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func chunkTagsToRows(tags: [String], maxWidth: CGFloat, font: UIFont) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentWidth: CGFloat = 0

        for tag in tags {
            let tagWidth = (tag as NSString).size(withAttributes: [.font: font]).width + 28 // padding
            if currentWidth + tagWidth > maxWidth {
                rows.append(currentRow)
                currentRow = [tag]
                currentWidth = tagWidth + 10
            } else {
                currentRow.append(tag)
                currentWidth += tagWidth + 10
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

}

enum ProfilePostTab {
    case created
    case liked
}
