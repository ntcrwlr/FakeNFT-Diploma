import XCTest
@testable import iOS_FakeNFT_Extended

final class iOS_FakeNFT_ExtendedTests: XCTestCase {
    func testExample() throws {
    }
}

@MainActor
final class EditProfileViewModelTests: XCTestCase {
    func testDraftDetectsChangesAndRestoringOriginalValue() {
        let model = EditProfileViewModel(profile: ProfileFixtures.preview)
        XCTAssertFalse(model.hasChanges)
        model.name = "Новое имя"
        XCTAssertTrue(model.hasChanges)
        model.name = ProfileFixtures.preview.name
        XCTAssertFalse(model.hasChanges)
        model.biography += "!"
        XCTAssertTrue(model.hasChanges)
        XCTAssertEqual(ProfileFixtures.preview.name, "Joaquin Phoenix")
    }

    func testAvatarLinkValidationAndRemoval() {
        let model = EditProfileViewModel(profile: ProfileFixtures.preview)
        model.updateAvatar(link: "file:///tmp/avatar.png")
        XCTAssertNil(model.avatarURL)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.hasChanges)
        model.updateAvatar(link: " https://example.com/avatar.png ")
        XCTAssertEqual(model.avatarURL?.absoluteString, "https://example.com/avatar.png")
        XCTAssertTrue(model.hasChanges)
        model.removeAvatar()
        XCTAssertNil(model.avatarURL)
        XCTAssertTrue(model.isAvatarRemoved)
        model.updateAvatar(link: "https://example.com/new.png")
        XCTAssertFalse(model.isAvatarRemoved)
    }

    func testSaveShowsLoadingAndPreventsDuplicateRequests() async {
        let model = EditProfileViewModel(profile: ProfileFixtures.preview)
        let saved = await model.save { draft in
            XCTAssertTrue(draft.isSaving)
            let duplicate = await draft.save { _ in XCTFail("Duplicate save") }
            XCTAssertFalse(duplicate)
        }
        XCTAssertTrue(saved)
        XCTAssertFalse(model.isSaving)
    }

    func testSaveFailurePreservesDraftAndClearsLoading() async {
        let model = EditProfileViewModel(profile: ProfileFixtures.preview)
        model.name = "Новое имя"
        let saved = await model.save { _ in throw URLError(.notConnectedToInternet) }
        XCTAssertFalse(saved)
        XCTAssertFalse(model.isSaving)
        XCTAssertEqual(model.name, "Новое имя")
        XCTAssertNotNil(model.errorMessage)
    }
}

@MainActor
final class ProfileWebsiteTests: XCTestCase {
    func testWebsiteAcceptsHTTPAndHTTPS() {
        for address in ["https://example.com/path?query=1", "http://example.com", " https://example.com \n"] {
            let model = makeModel(website: address)
            XCTAssertEqual(model.websiteURL?.host, "example.com")
        }
    }

    func testWebsiteRejectsEmptyMalformedAndUnsupportedLinks() {
        for address in ["", " \n", "example.com", "https://", "https://exa mple.com", "file:///tmp/site.html", "javascript:alert(1)"] {
            XCTAssertNil(makeModel(website: address).websiteURL, address)
        }
    }

    private func makeModel(website: String) -> ProfileViewModel {
        ProfileViewModel(profile: UserProfile(
            name: "User", biography: "Bio", websiteTitle: website,
            avatarAssetName: "ProfileAvatar", ownedNFTCount: 0, favoriteNFTCount: 0
        ))
    }
}

@MainActor
final class ProfileEditingTests: XCTestCase {
    func testSaveUpdatesProfileAndNextDraft() async {
        let profile = ProfileViewModel(profile: ProfileFixtures.preview)
        let draft = EditProfileViewModel(profile: profile.profile)
        draft.name = "Новое имя"
        draft.biography = "Новое описание"
        draft.website = "https://new.example.com"
        draft.updateAvatar(link: "https://example.com/photo.png")

        let saved = await draft.save { profile.updateProfile($0.updatedProfile) }

        XCTAssertTrue(saved)
        XCTAssertEqual(profile.profile.name, "Новое имя")
        XCTAssertEqual(profile.profile.biography, "Новое описание")
        XCTAssertEqual(profile.websiteURL?.host, "new.example.com")
        XCTAssertEqual(profile.profile.ownedNFTCount, ProfileFixtures.preview.ownedNFTCount)
        XCTAssertEqual(profile.profile.favoriteNFTCount, ProfileFixtures.preview.favoriteNFTCount)
        let reopened = EditProfileViewModel(profile: profile.profile)
        XCTAssertEqual(reopened.updatedProfile, draft.updatedProfile)
        XCTAssertFalse(reopened.hasChanges)
    }

    func testDiscardedDraftDoesNotChangeProfileAndNewSessionStartsWithMocks() {
        let profile = ProfileViewModel(profile: ProfileFixtures.preview)
        let draft = EditProfileViewModel(profile: profile.profile)
        draft.name = "Несохранённое имя"
        draft.removeAvatar()
        XCTAssertEqual(profile.profile, ProfileFixtures.preview)

        profile.updateProfile(draft.updatedProfile)
        let reopened = EditProfileViewModel(profile: profile.profile)
        XCTAssertTrue(reopened.isAvatarRemoved)
        XCTAssertFalse(reopened.hasChanges)
        XCTAssertEqual(ProfileViewModel(profile: ProfileFixtures.preview).profile, ProfileFixtures.preview)
    }
}

@MainActor
final class OwnedNFTsViewModelTests: XCTestCase {
    private let samples = [
        OwnedNFT(id: "1", name: "Spring", author: "Alice", price: Decimal(125) / 100,
                 rating: 5, imageName: "Spring", isFavorite: true),
        OwnedNFT(id: "2", name: "april", author: "Bob", price: Decimal(99) / 100,
                 rating: 2, imageName: nil, isFavorite: false),
        OwnedNFT(id: "3", name: "Lilo", author: "Carol", price: 10,
                 rating: 4, imageName: "Lilo", isFavorite: true)
    ]

    func testSelectionSortsItemsAndClosesMenu() {
        let model = OwnedNFTsViewModel(items: samples, settingsService: UserSettingsService(userDefaults: makeDefaults()))
        XCTAssertEqual(model.selectedSortOption, .rating)
        XCTAssertEqual(model.items.map(\.id), ["1", "3", "2"])

        for (option, expected) in [
            (OwnedNFTSortOption.price, ["2", "1", "3"]),
            (.rating, ["1", "3", "2"]),
            (.name, ["2", "3", "1"])
        ] {
            model.isSortMenuPresented = true
            model.selectSortOption(option)
            XCTAssertEqual(model.items.map(\.id), expected)
            XCTAssertEqual(model.selectedSortOption, option)
            XCTAssertFalse(model.isSortMenuPresented)
            for item in model.items {
                let original = samples.first { $0.id == item.id }!
                XCTAssertEqual(item.name, original.name)
                XCTAssertEqual(item.author, original.author)
                XCTAssertEqual(item.price, original.price)
                XCTAssertEqual(item.rating, original.rating)
                XCTAssertEqual(item.imageName, original.imageName)
                XCTAssertEqual(item.isFavorite, original.isFavorite)
            }
        }
    }

    func testUpdatedItemsUseCurrentSelection() {
        let model = OwnedNFTsViewModel(items: [], settingsService: UserSettingsService(userDefaults: makeDefaults()))
        model.selectSortOption(.price)
        model.updateItems(samples.reversed())
        XCTAssertEqual(model.items.map(\.id), ["2", "1", "3"])
        XCTAssertEqual(model.selectedSortOption, .price)
        XCTAssertFalse(model.isEmpty)
    }

    func testEmptyAndSingleItemListsForEveryCriterion() {
        let model = OwnedNFTsViewModel(items: [], settingsService: UserSettingsService(userDefaults: makeDefaults()))
        for option in OwnedNFTSortOption.allCases {
            model.updateItems([])
            model.selectSortOption(option)
            XCTAssertTrue(model.items.isEmpty)
            XCTAssertTrue(model.isEmpty)
            model.updateItems([samples[0]])
            XCTAssertEqual(model.items.map(\.id), ["1"])
        }
    }

    func testCancelPreservesSelectionAndOrder() {
        let model = OwnedNFTsViewModel(items: samples, settingsService: UserSettingsService(userDefaults: makeDefaults()))
        model.selectSortOption(.name)
        model.isSortMenuPresented = true
        model.closeSortMenu()
        XCTAssertFalse(model.isSortMenuPresented)
        XCTAssertEqual(model.selectedSortOption, .name)
        XCTAssertEqual(model.items.map(\.id), ["2", "3", "1"])
    }

    func testEqualValuesKeepSourceOrderAcrossSelections() {
        let model = OwnedNFTsViewModel(items: OwnedNFTFixtures.preview, settingsService: UserSettingsService(userDefaults: makeDefaults()))
        model.selectSortOption(.name)
        model.selectSortOption(.price)
        XCTAssertEqual(model.items.map(\.id), OwnedNFTFixtures.preview.map(\.id))
        model.selectSortOption(.rating)
        XCTAssertEqual(model.items.map(\.id), OwnedNFTFixtures.preview.map(\.id))
    }

    func testSelectionPersistsAndRestoresForEveryCriterion() {
        let defaults = makeDefaults()
        let model = OwnedNFTsViewModel(items: samples, settingsService: UserSettingsService(userDefaults: defaults))
        for (option, expected) in [
            (OwnedNFTSortOption.price, ["2", "1", "3"]),
            (.rating, ["1", "3", "2"]),
            (.name, ["2", "3", "1"])
        ] {
            model.selectSortOption(option)
            XCTAssertEqual(defaults.string(forKey: "profile.ownedNFTs.sortOption"), option.rawValue)

            let reopened = OwnedNFTsViewModel(items: samples, settingsService: UserSettingsService(userDefaults: defaults))
            XCTAssertEqual(reopened.selectedSortOption, option)
            XCTAssertEqual(reopened.items.map(\.id), expected)
            reopened.updateItems(samples.reversed())
            XCTAssertEqual(reopened.items.map(\.id), expected)
        }
    }

    func testUnknownSavedCriterionFallsBackToRating() {
        let defaults = makeDefaults()
        defaults.set("unknown", forKey: "profile.ownedNFTs.sortOption")
        let model = OwnedNFTsViewModel(items: samples, settingsService: UserSettingsService(userDefaults: defaults))
        XCTAssertEqual(model.selectedSortOption, .rating)
        XCTAssertEqual(model.items.map(\.id), ["1", "3", "2"])
        model.selectSortOption(.name)
        XCTAssertEqual(defaults.string(forKey: "profile.ownedNFTs.sortOption"), "name")
    }

    func testViewModelReadsAndUpdatesInjectedSettingsService() {
        let service = UserSettingsServiceStub()
        service.ownedNFTSortOption = .name
        let model = OwnedNFTsViewModel(items: samples, settingsService: service)
        XCTAssertEqual(model.selectedSortOption, .name)
        XCTAssertEqual(model.items.map(\.id), ["2", "3", "1"])

        model.selectSortOption(.price)
        XCTAssertEqual(service.ownedNFTSortOption, .price)
        model.closeSortMenu()
        XCTAssertEqual(service.ownedNFTSortOption, .price)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "OwnedNFTsViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        addTeardownBlock {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }
}

private final class UserSettingsServiceStub: UserSettingsServiceProtocol {
    var ownedNFTSortOption: OwnedNFTSortOption = .rating
}
