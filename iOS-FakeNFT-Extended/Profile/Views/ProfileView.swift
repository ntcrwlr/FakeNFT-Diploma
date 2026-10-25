import SwiftUI

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    @ScaledMetric(relativeTo: .body) private var biographySize = 13
    @ScaledMetric(relativeTo: .body) private var websiteSize = 15

    // Navigation belongs to the composition layer and will be connected separately.
    private let onEdit: () -> Void
    private let onOwnedNFTs: () -> Void
    private let onFavoriteNFTs: () -> Void
    private let onWebsite: (URL) -> Void

    init(
        viewModel: ProfileViewModel,
        onEdit: @escaping () -> Void = {},
        onOwnedNFTs: @escaping () -> Void = {},
        onFavoriteNFTs: @escaping () -> Void = {},
        onWebsite: @escaping (URL) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onEdit = onEdit
        self.onOwnedNFTs = onOwnedNFTs
        self.onFavoriteNFTs = onFavoriteNFTs
        self.onWebsite = onWebsite
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                editButton
                    .padding(.bottom, 20)
                identity
                    .padding(.bottom, 24)
                Text(viewModel.profile.biography)
                    .font(.system(size: biographySize))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)
                Button {
                    if let url = viewModel.websiteURL {
                        onWebsite(url)
                    }
                } label: {
                    Text(viewModel.profile.websiteTitle)
                        .font(.system(size: websiteSize))
                        .foregroundStyle(Color(uiColor: .profileLink))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.websiteURL == nil)
                .accessibilityIdentifier("profile.website")
                .accessibilityHint("Сайт пользователя")
                .padding(.bottom, 18)
                VStack(spacing: 0) {
                    ProfileMenuRow(title: "Мои NFT", count: viewModel.profile.ownedNFTCount, action: onOwnedNFTs)
                    ProfileMenuRow(title: "Избранные NFT", count: viewModel.profile.favoriteNFTCount, action: onFavoriteNFTs)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color(uiColor: .profileForeground))
        .background(Color(uiColor: .profileBackground).ignoresSafeArea())
        .toolbarBackground(Color(uiColor: .profileBackground), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .accessibilityIdentifier("profile.screen")
    }

    private var editButton: some View {
        HStack {
            Spacer()
            Button(action: onEdit) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 26, weight: .regular))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Редактировать профиль")
            .accessibilityIdentifier("profile.edit")
        }
    }

    private var identity: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                avatar
                name.fixedSize()
            }
            VStack(alignment: .leading, spacing: 16) {
                avatar
                name
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var avatar: some View {
        Image(viewModel.profile.avatarAssetName)
            .resizable()
            .scaledToFill()
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            .accessibilityLabel("Фото пользователя")
    }

    private var name: some View {
        Text(viewModel.profile.name)
            .font(.system(.title2, weight: .bold))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview("Profile (Light)") {
    ProfileView(viewModel: ProfileViewModel(profile: ProfileFixtures.preview))
}

#Preview("Profile (Dark)") {
    ProfileView(viewModel: ProfileViewModel(profile: ProfileFixtures.preview))
        .preferredColorScheme(.dark)
}
