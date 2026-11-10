import SwiftUI

struct CollectionNftCellView: View {
    let nft: Nft
    let state: NftCellState
    let onLike: () -> Void
    let onCart: () -> Void
    let onOpen: () -> Void

    private var filledStars: Int {
        min(Constants.starCount, max(0, nft.rating / 2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cover
            VStack(alignment: .leading, spacing: 4) {
                Button(action: onOpen) {
                    rating
                }
                .buttonStyle(.plain)
                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Button(action: onOpen) {
                            Text(nft.name)
                                .font(Font(UIFont.bodyBold))
                                .foregroundStyle(Color.black)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Text(priceText)
                            .font(Font(UIFont.caption2))
                            .foregroundStyle(Color.black)
                            .lineLimit(1)
                    }
                    cartButton
                        .padding(.trailing, Constants.cartTrailingInset)
                }
            }
            .padding(.top, 8)
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
                    .padding(.top, 6)
                    .padding(.trailing, 6)
                    .zIndex(1)
            }
    }

    private var likeButton: some View {
        Button(action: onLike) {
            Image(systemName: state.isLiked ? "heart.fill" : "heart")
                .font(.system(size: Constants.heartSize, weight: .regular))
                .foregroundStyle(state.isLiked ? Color.red : Color.white)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 0)
                .frame(width: Constants.heartTapSize, height: Constants.heartTapSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!state.isLikeEnabled)
        .accessibilityLabel(state.isLiked ? Constants.likedTitle : Constants.likeTitle)
    }

    private var cartButton: some View {
        Button(action: onCart) {
            Image(state.isInCart ? Constants.removeFromCartImage : Constants.addToCartImage)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.cartSize, height: Constants.cartSize)
                .frame(width: Constants.cartTapSize, height: Constants.cartTapSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!state.isCartEnabled)
        .accessibilityLabel(state.isInCart ? Constants.removeFromCartTitle : Constants.addToCartTitle)
    }

    private var rating: some View {
        HStack(spacing: Constants.starSpacing) {
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
        let value = NumberFormatter.nftPrice.string(from: nft.price as NSDecimalNumber) ?? "\(nft.price)"
        return "\(value) ETH"
    }
}

private enum Constants {
    static let coverCornerRadius: CGFloat = 12
    static let starCount = 5
    static let starSize: CGFloat = 12
    static let starSpacing: CGFloat = 2
    static let heartSize: CGFloat = 18
    static let heartTapSize: CGFloat = 28
    static let cartSize: CGFloat = 40
    static let cartTapSize: CGFloat = 40
    static let cartTrailingInset: CGFloat = 8
    static let addToCartImage = "Property 1=Add"
    static let removeFromCartImage = "Property 1=Delete"
    static let likeTitle = NSLocalizedString("Catalog.like", comment: "")
    static let likedTitle = NSLocalizedString("Catalog.liked", comment: "")
    static let addToCartTitle = NSLocalizedString("Catalog.addToCart", comment: "")
    static let removeFromCartTitle = NSLocalizedString("Catalog.removeFromCart", comment: "")
}
