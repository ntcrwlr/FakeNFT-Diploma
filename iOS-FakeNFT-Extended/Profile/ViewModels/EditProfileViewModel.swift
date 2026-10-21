import Foundation
import Observation

@MainActor
@Observable
final class EditProfileViewModel {
    var name: String
    var biography: String
    var website: String
    private(set) var avatarURL: URL?
    private(set) var isAvatarRemoved = false
    private(set) var isSaving = false
    var errorMessage: String?
    let avatarAssetName: String
    private let initialName: String
    private let initialBiography: String
    private let initialWebsite: String

    var hasChanges: Bool {
        name != initialName || biography != initialBiography || website != initialWebsite
            || avatarURL != nil || isAvatarRemoved
    }

    init(profile: UserProfile) {
        name = profile.name
        biography = profile.biography
        website = profile.websiteTitle
        avatarAssetName = profile.avatarAssetName
        initialName = profile.name
        initialBiography = profile.biography
        initialWebsite = profile.websiteTitle
    }

    func updateAvatar(link: String) {
        let value = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host, !host.isEmpty else {
            errorMessage = "Введите корректную ссылку на фото (http или https)."
            return
        }
        errorMessage = nil
        avatarURL = url
        isAvatarRemoved = false
    }

    func removeAvatar() {
        avatarURL = nil
        isAvatarRemoved = true
    }

    func save(using action: (EditProfileViewModel) async throws -> Void) async -> Bool {
        guard !isSaving else { return false }
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            try await action(self)
            try Task.checkCancellation()
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = "Не удалось сохранить изменения. Попробуйте ещё раз."
            return false
        }
    }
}
