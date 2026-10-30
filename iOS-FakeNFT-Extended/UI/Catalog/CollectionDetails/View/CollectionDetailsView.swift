import SwiftUI

struct CollectionDetailsView: View {
    @State private var viewModel: CollectionDetailsViewModel

    init(collection: NftCollection, nftService: NftService) {
        _viewModel = State(
            initialValue: CollectionDetailsViewModel(collection: collection, nftService: nftService)
        )
    }

    var body: some View {
        ScrollView {
            content
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            cover
            descriptionBlock
            nftsContent
        }
    }

    private var cover: some View {
        Color(white: 0.95)
            .overlay {
                AsyncImage(url: URL(string: viewModel.collection.cover)) { phase in
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
            Text(viewModel.collection.name)
                .font(Font(UIFont.headline3))
                .foregroundStyle(Color.black)
            author
            Text(viewModel.collection.description)
                .font(Font(UIFont.caption2))
                .foregroundStyle(Color.black)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var author: some View {
        (
            Text(Constants.authorPrefix)
                .foregroundStyle(Color.black)
            + Text(viewModel.collection.author)
                .foregroundStyle(Color.blue)
        )
        .font(Font(UIFont.caption2))
    }

    @ViewBuilder
    private var nftsContent: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        case .error:
            errorContent
        case .success(let nfts):
            nftGrid(nfts)
        }
    }

    private func nftGrid(_ nfts: [Nft]) -> some View {
        LazyVGrid(columns: Constants.columns, spacing: Constants.gridRowSpacing) {
            ForEach(nfts, id: \.id) { nft in
                CollectionNftCell(nft: nft)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 24)
    }

    private var errorContent: some View {
        VStack(spacing: 16) {
            Text(Constants.errorTitle)
                .font(.headline)
            Text(Constants.errorMessage)
                .multilineTextAlignment(.center)
            Button(Constants.retryTitle) {
                Task {
                    await viewModel.load()
                }
            }
        }
        .padding(24)
    }
}

private enum Constants {
    static let coverHeight: CGFloat = 250
    static let gridRowSpacing: CGFloat = 28
    static let columns = [
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9)
    ]

    static let authorPrefix = NSLocalizedString("Collection.author", comment: "")
    static let errorTitle = NSLocalizedString("Error.title", comment: "")
    static let errorMessage = NSLocalizedString("Error.network", comment: "")
    static let retryTitle = NSLocalizedString("Error.repeat", comment: "")
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
                nfts: ["1", "2", "3", "4", "5", "6"]
            ),
            nftService: PreviewNftService()
        )
    }
}
