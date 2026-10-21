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
