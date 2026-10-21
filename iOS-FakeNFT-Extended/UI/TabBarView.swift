import SwiftUI

struct TabBarView: View {
    @State private var profileViewModel = ProfileViewModel(profile: ProfileFixtures.preview)
    @State private var showsEditProfile = false

    var body: some View {
        TabView {
            ProfileView(viewModel: profileViewModel, onEdit: { showsEditProfile = true })
                .tabItem {
                    Label(NSLocalizedString("Tab.profile", comment: ""), systemImage: "person.crop.circle.fill")
                }
                .fullScreenCover(isPresented: $showsEditProfile) {
                    EditProfileView(viewModel: EditProfileViewModel(profile: profileViewModel.profile))
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
