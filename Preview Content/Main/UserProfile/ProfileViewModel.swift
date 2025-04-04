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
    @Published var isSubscribed: Bool = false
    @Published var subscriptionsCount: Int = 0
    @Published var followersCount: Int = 0


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
    
    func checkSubscriptionStatus() {
        guard let targetId = userId,
              let currentId = FirebaseUserService.shared.currentUserId,
              currentId != targetId else { return }

        FirebaseUserService.shared.isSubscribed(to: targetId, from: currentId) { [weak self] isSubscribed in
            DispatchQueue.main.async {
                self?.isSubscribed = isSubscribed
            }
        }
    }

    func toggleSubscription() {
        guard let targetId = userId,
              let currentId = FirebaseUserService.shared.currentUserId,
              currentId != targetId else { return }

        if isSubscribed {
            FirebaseUserService.shared.unsubscribe(from: targetId, by: currentId) { [weak self] error in
                DispatchQueue.main.async {
                    if error == nil {
                        self?.isSubscribed = false
                        self?.fetchFollowersCount()
                    }
                }
            }
        } else {
            FirebaseUserService.shared.subscribe(to: targetId, from: currentId) { [weak self] error in
                DispatchQueue.main.async {
                    if error == nil {
                        self?.isSubscribed = true
                        self?.fetchFollowersCount()
                    }
                }
            }
        }
    }

    func fetchFollowersCount() {
        guard let uid = userId else { return }

        FirebaseUserService.shared.fetchFollowers(for: uid) { [weak self] followers in
            DispatchQueue.main.async {
                self?.followersCount = followers.count
            }
        }
    }

    func fetchSubscriptionsCount() {
        guard let uid = userId else { return }

        FirebaseUserService.shared.fetchSubscriptions(for: uid) { [weak self] subscriptions in
            DispatchQueue.main.async {
                self?.subscriptionsCount = subscriptions.count
            }
        }
    }

}

enum ProfilePostTab {
    case created
    case liked
}
