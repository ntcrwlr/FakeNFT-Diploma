import SwiftUI

struct CollectionNftCellView: View {
    let nft: Nft
    let isLiked: Bool
    let isLikeEnabled: Bool
    let isInCart: Bool
    let isCartEnabled: Bool
    let onLike: () -> Void
    let onCart: () -> Void
    let onOpen: () -> Void

    private var filledStars: Int {
        min(Constants.starCount, max(0, nft.rating / 2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cover
            Button(action: onOpen) {
                details
            }
            .buttonStyle(.plain)
            priceRow
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            rating
            Text(nft.name)
                .font(Font(UIFont.bodyBold))
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var priceRow: some View {
        HStack(spacing: 4) {
            Text(priceText)
                .font(Font(UIFont.caption2))
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            cartButton
        }
    }

    private var cover: some View {
        Color(white: 0.95)
            .overlay {
                AsyncImage(url: nft.images.first) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Constants.coverCornerRadius))
            .overlay {
                Button(action: onOpen) {
                    Color.clear
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .overlay(alignment: .topTrailing) {
                likeButton
                    .zIndex(1)
            }
    }

    private var likeButton: some View {
        Button(action: onLike) {
            Image(systemName: "heart.fill")
                .font(.system(size: Constants.heartSize))
                .foregroundStyle(isLiked ? Color.red : Color.white)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                .frame(width: Constants.heartTapSize, height: Constants.heartTapSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isLikeEnabled)
        .accessibilityLabel(isLiked ? Constants.likedTitle : Constants.likeTitle)
    }

    private var cartButton: some View {
        Button(action: onCart) {
            Image(systemName: isInCart ? "xmark" : "cart")
                .font(.system(size: Constants.cartSize, weight: .medium))
                .foregroundStyle(Color.black)
                .frame(width: Constants.cartTapSize, height: Constants.cartTapSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isCartEnabled)
        .accessibilityLabel(isInCart ? Constants.removeFromCartTitle : Constants.addToCartTitle)
    }

    private var rating: some View {
        HStack(spacing: 2) {
            ForEach(0..<Constants.starCount, id: \.self) { index in
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.starSize, height: Constants.starSize)
                    .foregroundStyle(index < filledStars ? Color.yellow : Color(white: 0.85))
            }
        }
    }

    private var priceText: String {
        let value = NumberFormatter.nftPrice.string(from: NSNumber(value: nft.price)) ?? "\(nft.price)"
        return "\(value) ETH"
    }
}

private enum Constants {
    static let coverCornerRadius: CGFloat = 12
    static let starCount = 5
    static let starSize: CGFloat = 12
    static let heartSize: CGFloat = 16
    static let heartTapSize: CGFloat = 32
    static let cartSize: CGFloat = 14
    static let cartTapSize: CGFloat = 24
    static let likeTitle = NSLocalizedString("Catalog.like", comment: "")
    static let likedTitle = NSLocalizedString("Catalog.liked", comment: "")
    static let addToCartTitle = NSLocalizedString("Catalog.addToCart", comment: "")
    static let removeFromCartTitle = NSLocalizedString("Catalog.removeFromCart", comment: "")
}
