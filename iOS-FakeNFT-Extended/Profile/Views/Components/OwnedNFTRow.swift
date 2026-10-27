import SwiftUI

struct OwnedNFTRow: View {
    let item: OwnedNFT
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 20) {
            artwork
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    details
                    price
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                details
                    .frame(maxWidth: .infinity, alignment: .leading)
                price
                    .frame(minWidth: 98, alignment: .leading)
            }
        }
        .foregroundStyle(Color(uiColor: .profileForeground))
        .accessibilityElement(children: .combine)
    }

    private var artwork: some View {
        ZStack {
            if let imageName = item.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                // Offline placeholder until the original NFT artwork is supplied.
                LinearGradient(
                    colors: [.pink.opacity(0.25), .purple.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "photo.artframe")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 108, height: 108)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topTrailing) {
            if item.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .padding(10)
            }
        }
        .accessibilityLabel(item.isFavorite ? "В избранном" : "Изображение NFT")
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(.system(.body, weight: .bold))
            HStack(spacing: 0) {
                ForEach(0..<5) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(index < item.rating ? Color.yellow : Color(uiColor: .profileFieldBackground))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Рейтинг: \(item.rating) из 5")
            Text("от \(item.author)")
                .font(.system(size: 13))
        }
    }

    private var price: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Цена")
                .font(.system(size: 13))
            Text(item.formattedPrice)
                .font(.system(.body, weight: .bold))
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}
