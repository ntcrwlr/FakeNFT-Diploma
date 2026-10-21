import SwiftUI

struct CatalogView: View {
    @AppStorage(CatalogSort.storageKey) private var sortRawValue = CatalogSort.nftCount.rawValue
    @State private var viewModel: CatalogViewModel

    init(collectionService: CollectionService) {
        let storedSort = UserDefaults.standard.string(forKey: CatalogSort.storageKey)
        let sort = CatalogSort(rawValue: storedSort ?? "") ?? .nftCount
        _viewModel = State(initialValue: CatalogViewModel(collectionService: collectionService, sort: sort))
    }

    init(previewCollections: [NftCollection]) {
        _viewModel = State(
            initialValue: CatalogViewModel(previewCollections: previewCollections, sort: .nftCount)
        )
    }

    var body: some View {
        NavigationStack {
            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Section(Constants.sortTitle) {
                                Button(Constants.sortByName) {
                                    sortRawValue = CatalogSort.name.rawValue
                                }
                                Button(Constants.sortByCount) {
                                    sortRawValue = CatalogSort.nftCount.rawValue
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 17))
                                .foregroundStyle(Color.black)
                        }
                        .accessibilityLabel(Constants.sortTitle)
                        .tint(Color.black)
                    }
                }
                .onChange(of: sortRawValue) { _, newValue in
                    viewModel.setSort(CatalogSort(rawValue: newValue) ?? .nftCount)
                }
                .task {
                    await viewModel.loadIfNeeded()
                }
        }
    }

    @ViewBuilder
    private var screen: some View {
        switch viewModel.phase {
        case .idle, .loading:
            ProgressView()
        case .failed:
            errorContent
        case .loaded(let collections):
            collectionsList(collections)
        }
    }

    private func collectionsList(_ collections: [NftCollection]) -> some View {
        List(collections) { collection in
            CatalogCollectionRow(collection: collection)
                .listRowSeparator(.hidden)
                .listRowInsets(Constants.rowInsets)
                .listRowBackground(Color.white)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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

private struct CatalogCollectionRow: View {
    let collection: NftCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cover
            Text("\(collection.name) (\(collection.nfts.count))")
                .font(Font(UIFont.bodyBold))
                .foregroundStyle(Color.black)
                .lineLimit(2)
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
            .clipShape(RoundedRectangle(cornerRadius: Constants.coverCornerRadius))
    }
}

private enum Constants {
    static let coverHeight: CGFloat = 140
    static let coverCornerRadius: CGFloat = 12
    static let rowInsets = EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

    static let sortTitle = NSLocalizedString("Catalog.sort", comment: "")
    static let sortByName = NSLocalizedString("Catalog.sort.byName", comment: "")
    static let sortByCount = NSLocalizedString("Catalog.sort.byCount", comment: "")
    static let errorTitle = NSLocalizedString("Error.title", comment: "")
    static let errorMessage = NSLocalizedString("Error.network", comment: "")
    static let retryTitle = NSLocalizedString("Error.repeat", comment: "")
}

#Preview {
    CatalogView(previewCollections: [
        NftCollection(
            id: "peach",
            name: "Peach",
            cover: "",
            description: "",
            author: "",
            nfts: (0..<11).map(String.init)
        ),
        NftCollection(
            id: "blue",
            name: "Blue",
            cover: "",
            description: "",
            author: "",
            nfts: (0..<6).map(String.init)
        ),
        NftCollection(
            id: "brown",
            name: "Brown",
            cover: "",
            description: "",
            author: "",
            nfts: (0..<8).map(String.init)
        )
    ])
}
