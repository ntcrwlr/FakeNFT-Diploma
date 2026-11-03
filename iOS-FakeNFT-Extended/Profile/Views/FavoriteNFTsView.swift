import SwiftUI

struct FavoriteNFTsView: View {
    @State private var viewModel: FavoriteNFTsViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(viewModel: FavoriteNFTsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    init(items: [FavoriteNFT]) {
        self.init(viewModel: FavoriteNFTsViewModel(items: items))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(uiColor: .profileBackground).ignoresSafeArea()
                if viewModel.items.isEmpty {
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
                            ForEach(viewModel.items) { item in
                                FavoriteNFTCard(item: item, isRemoving: viewModel.removingIDs.contains(item.id)) {
                                    Task { await viewModel.removeFavorite(id: item.id) }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .frame(maxWidth: 600)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .foregroundStyle(Color(uiColor: .profileForeground))
        .navigationTitle(NSLocalizedString("FavoriteNFTs.title", comment: "Favorite NFTs screen title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Color(uiColor: .profileBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .accessibilityIdentifier("favoriteNFTs.screen")
        .task { await viewModel.loadFavorites() }
        .alert("FavoriteNFTs.removalError.title", isPresented: Binding(
            get: { viewModel.failedRemovalID != nil },
            set: { if !$0 { viewModel.dismissRemovalError() } }
        ), presenting: viewModel.failedRemovalID) { id in
            Button("FavoriteNFTs.removalError.retry") {
                Task { await viewModel.removeFavorite(id: id) }
            }
            Button("FavoriteNFTs.removalError.cancel", role: .cancel) {
                viewModel.dismissRemovalError()
            }
        } message: { _ in
            Text("FavoriteNFTs.removalError.message")
        }
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
