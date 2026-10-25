import SwiftUI

struct TabBarView: View {
    @State private var profileViewModel = ProfileViewModel(profile: ProfileFixtures.preview)
    @State private var showsEditProfile = false
    @State private var websitePath: [URL] = []

    var body: some View {
        TabView {
            NavigationStack(path: $websitePath) {
                ProfileView(
                    viewModel: profileViewModel,
                    onEdit: { showsEditProfile = true },
                    onWebsite: { websitePath.append($0) }
                )
                .navigationDestination(for: URL.self) { url in
                    ProfileWebsiteView(url: url)
                }
            }
            .tabItem {
                Label(NSLocalizedString("Tab.profile", comment: ""), systemImage: "person.crop.circle.fill")
            }
            .fullScreenCover(isPresented: $showsEditProfile) {
                EditProfileView(
                    viewModel: EditProfileViewModel(profile: profileViewModel.profile),
                    onSave: { draft in
                        try Task.checkCancellation()
                        profileViewModel.updateProfile(draft.updatedProfile)
                    }
                )
            }

            TestCatalogView()
                .tabItem {
                    Label(
                        NSLocalizedString("Tab.catalog", comment: ""),
                        systemImage: "square.stack.3d.up.fill"
                    )
                }
                .backgroundStyle(.background)
        }
        .tint(Color(uiColor: .profileLink))
        .toolbarBackground(Color(uiColor: .profileBackground), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
