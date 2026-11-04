import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var profile: UserProfile
    private(set) var loadedProfile: Profile?
    private(set) var loadingError: Error?
    private let profileService: ProfileService?
    private var isLoading = false

    var websiteURL: URL? {
        let value = profile.websiteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.contains(where: { $0.isWhitespace }),
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    func saveProfile(_ update: ProfileUpdate) async throws {
        guard let profileService else { throw SaveError.serviceUnavailable }
        try Task.checkCancellation()
        let response = try await profileService.saveProfile(update)
        try Task.checkCancellation()
        loadedProfile = response
        profile = UserProfile(profile: response)
    }

    init(profile: UserProfile) {
        self.profile = profile
        profileService = nil
    }

    init(profileService: ProfileService) {
        self.profileService = profileService
        profile = .empty
    }

    func loadProfile() async {
        guard let profileService, !isLoading else { return }
        isLoading = true
        loadingError = nil
        defer { isLoading = false }

        do {
            let response = try await profileService.loadProfile()
            try Task.checkCancellation()
            loadedProfile = response
            profile = UserProfile(profile: response)
        } catch is CancellationError {
            return
        } catch {
            loadingError = error
        }
    }

    private enum SaveError: Error {
        case serviceUnavailable
    }
}
