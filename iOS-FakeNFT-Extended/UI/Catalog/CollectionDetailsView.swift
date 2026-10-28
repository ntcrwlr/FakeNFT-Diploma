import SwiftUI

struct CollectionDetailsView: View {
    let collection: NftCollection

    var body: some View {
        ScrollView {
            content
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            cover
            descriptionBlock
        }
    }

    private var cover: some View {
        Color(white: 0.95)
            .overlay {
                AsyncImage(url: URL(string: collection.cover)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
            .frame(height: Constants.coverHeight)
            .frame(maxWidth: .infinity)
            .clipped()
    }

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(collection.name)
                .font(Font(UIFont.headline3))
                .foregroundStyle(Color.black)
            author
            Text(collection.description)
                .font(Font(UIFont.caption2))
                .foregroundStyle(Color.black)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    private var author: some View {
        (
            Text(Constants.authorPrefix)
                .foregroundStyle(Color.black)
            + Text(collection.author)
                .foregroundStyle(Color.blue)
        )
        .font(Font(UIFont.caption2))
    }
}

private enum Constants {
    static let coverHeight: CGFloat = 250
    static let authorPrefix = NSLocalizedString("Collection.author", comment: "")
}

#Preview {
    NavigationStack {
        CollectionDetailsView(
            collection: NftCollection(
                id: "peach",
                name: "Peach",
                cover: "",
                description: "Персиковый — как облака над закатным солнцем в океане.",
                author: "https://example.com/john-doe",
                nfts: []
            )
        )
    }
}
