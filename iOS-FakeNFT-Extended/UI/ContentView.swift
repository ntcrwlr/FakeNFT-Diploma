import SwiftUI

struct ContentView: View {
    @Environment(ServicesAssembly.self) private var servicesAssembly

    var body: some View {
        TabBarView(profileViewModel: makeProfileViewModel())
    }

    private func makeProfileViewModel() -> ProfileViewModel {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-profile-fixture") {
            return ProfileViewModel(profile: ProfileFixtures.preview)
        }
        #endif
        return ProfileViewModel(profileService: servicesAssembly.profileService)
    }
}
