import SwiftUI

struct FavoriteNFTsView: View {
    let items: [FavoriteNFT]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(uiColor: .profileBackground).ignoresSafeArea()
                if items.isEmpty {
                    Text(NSLocalizedString("FavoriteNFTs.empty", comment: "No favorite NFTs message"))
                        .font(.system(.body, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("favoriteNFTs.empty")
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 12, alignment: .leading),
                                count: geometry.size.width < 350 || dynamicTypeSize.isAccessibilitySize ? 1 : 2
                            ),
                            spacing: 20
                        ) {
                            ForEach(items) { item in
                                // Removing favorites is implemented in a separate task.
                                FavoriteNFTCard(item: item, onFavoriteTap: {})
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .frame(maxWidth: 600)
                        .frame(maxWidth: .infinity)
                    }
                    .safeAreaInset(edge: .top, spacing: 0) { header }
                }
            }
            .overlay(alignment: .topLeading) {
                if items.isEmpty {
                    backButton.padding(.leading, 4)
                }
            }
        }
        .foregroundStyle(Color(uiColor: .profileForeground))
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar, .tabBar)
        .accessibilityIdentifier("favoriteNFTs.screen")
    }

    private var header: some View {
        Text(NSLocalizedString("FavoriteNFTs.title", comment: "Favorite NFTs screen title"))
            .font(.system(.body, weight: .bold))
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
            .padding(.horizontal, 48)
            .frame(maxWidth: .infinity, minHeight: 44)
            .overlay(alignment: .leading) { backButton.padding(.leading, 4) }
            .background(Color(uiColor: .profileBackground))
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .medium))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(NSLocalizedString("FavoriteNFTs.back", comment: "Return to previous screen"))
        .accessibilityIdentifier("favoriteNFTs.back")
    }
}

#Preview("Favorites — Light") {
    NavigationStack { FavoriteNFTsView(items: FavoriteNFTFixtures.preview) }
}

#Preview("Favorites — Dark") {
    NavigationStack { FavoriteNFTsView(items: FavoriteNFTFixtures.preview) }
        .preferredColorScheme(.dark)
}

#Preview("No favorites — Light") {
    NavigationStack { FavoriteNFTsView(items: []) }
}

#Preview("No favorites — Dark") {
    NavigationStack { FavoriteNFTsView(items: []) }
        .preferredColorScheme(.dark)
}

#Preview("Favorites — Long name", traits: .fixedLayout(width: 375, height: 812)) {
    FavoriteNFTsView(items: [FavoriteNFT(
        id: "long-name", name: "NFT с очень длинным названием", price: Decimal(178) / 100,
        rating: 5, imageName: "April"
    )])
}

#Preview("Favorites — Accessibility") {
    FavoriteNFTsView(items: FavoriteNFTFixtures.preview)
        .environment(\.dynamicTypeSize, .accessibility1)
}
