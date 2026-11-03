import SwiftUI

struct FavoriteNFTCard: View {
    let item: FavoriteNFT
    var onFavoriteTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            artwork
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
                .overlay(alignment: .topTrailing) {
                    Button(action: onFavoriteTap) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(uiColor: UIColor(hexString: "F56B6C")))
                            .frame(width: 44, height: 44, alignment: .topTrailing)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(4)
                    .accessibilityLabel(String(
                        format: NSLocalizedString("FavoriteNFTs.favorite", comment: "Favorite NFT button; %@ is the name"),
                        item.name
                    ))
                    .accessibilityIdentifier("favoriteNFTs.heart.\(item.id)")
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(.body, weight: .bold))
                    .lineLimit(1)
                HStack(spacing: 0) {
                    ForEach(0..<5) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(index < item.rating
                                ? Color(uiColor: UIColor(hexString: "FEEA1A"))
                                : Color(uiColor: .profileFieldBackground))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(
                    format: NSLocalizedString("FavoriteNFTs.rating", comment: "NFT rating out of five"),
                    item.rating
                ))
                Text(item.formattedPrice)
                    .font(.system(.subheadline))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color(uiColor: .profileForeground))
        .accessibilityElement(children: .contain)
    }

    private var artwork: some View {
        Group {
            if let imageName = item.imageName {
                Image(imageName).resizable()
            } else {
                Color(uiColor: .profileFieldBackground)
            }
        }
    }
}

#Preview("Favorite card — Light", traits: .fixedLayout(width: 180, height: 100)) {
    FavoriteNFTCard(item: FavoriteNFTFixtures.preview[0], onFavoriteTap: {})
        .padding(8)
        .background(Color(uiColor: .profileBackground))
}

#Preview("Favorite card — Dark", traits: .fixedLayout(width: 180, height: 100)) {
    FavoriteNFTCard(item: FavoriteNFTFixtures.preview[5], onFavoriteTap: {})
        .padding(8)
        .background(Color(uiColor: .profileBackground))
        .preferredColorScheme(.dark)
}
