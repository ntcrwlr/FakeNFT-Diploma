import SwiftUI

struct CollectionNftCellView: View {
    let nft: Nft

    private var filledStars: Int {
        min(Constants.starCount, max(0, nft.rating / 2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cover
            rating
            Text(nft.name)
                .font(Font(UIFont.bodyBold))
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(priceText)
                .font(Font(UIFont.caption2))
                .foregroundStyle(Color.black)
                .lineLimit(1)
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
}
