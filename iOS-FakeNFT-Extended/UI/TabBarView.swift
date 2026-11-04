import SwiftUI

struct TabBarView: View {
    @Environment(ServicesAssembly.self) private var servicesAssembly
    @State private var profileViewModel: ProfileViewModel
    @State private var showsEditProfile = false
    @State private var showsOwnedNFTs = false
    @State private var showsFavoriteNFTs = false
    @State private var websitePath: [URL] = []

    init(profileViewModel: ProfileViewModel) {
        _profileViewModel = State(initialValue: profileViewModel)
    }

    var body: some View {
        TabView {
            NavigationStack(path: $websitePath) {
                ProfileView(
                    viewModel: profileViewModel,
                    onEdit: { showsEditProfile = true },
                    onOwnedNFTs: { showsOwnedNFTs = true },
                    onFavoriteNFTs: { showsFavoriteNFTs = true },
                    onWebsite: { websitePath.append($0) }
                )
                .navigationDestination(isPresented: $showsOwnedNFTs) {
                    OwnedNFTsView(viewModel: OwnedNFTsViewModel(items: OwnedNFTFixtures.preview))
                }
                .navigationDestination(isPresented: $showsFavoriteNFTs) {
                    FavoriteNFTsView(viewModel: FavoriteNFTsViewModel(service: servicesAssembly.favoriteNFTService))
                }
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
                        try await profileViewModel.saveProfile(draft.profileUpdate)
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
