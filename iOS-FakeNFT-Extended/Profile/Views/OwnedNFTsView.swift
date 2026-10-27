import SwiftUI

struct OwnedNFTsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: OwnedNFTsViewModel

    init(viewModel: OwnedNFTsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color(uiColor: .profileBackground).ignoresSafeArea()
            if viewModel.isEmpty {
                Text("У Вас ещё нет NFT")
                    .font(.system(.body, weight: .bold))
                    .accessibilityIdentifier("ownedNFTs.empty")
            } else {
                ScrollView {
                    LazyVStack(spacing: 32) {
                        ForEach(viewModel.items) { item in
                            OwnedNFTRow(item: item)
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
        .foregroundStyle(Color(uiColor: .profileForeground))
        .overlay(alignment: .topLeading) {
            if viewModel.isEmpty {
                backButton.padding(.leading, 4)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar, .tabBar)
        .confirmationDialog("Сортировка", isPresented: $viewModel.isSortMenuPresented, titleVisibility: .visible) {
            Button("По цене") { viewModel.selectSortOption(.price) }
            Button("По рейтингу") { viewModel.selectSortOption(.rating) }
            Button("По названию") { viewModel.selectSortOption(.name) }
            Button("Закрыть", role: .cancel, action: viewModel.closeSortMenu)
        }
        .accessibilityIdentifier("ownedNFTs.screen")
    }

    private var header: some View {
        HStack {
            backButton
            Spacer()
            Text("Мои NFT")
                .font(.system(.body, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
                viewModel.isSortMenuPresented = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 24))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Сортировка")
            .accessibilityIdentifier("ownedNFTs.sort")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
        .padding(.bottom, 16)
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
        .accessibilityLabel("Назад")
        .accessibilityIdentifier("ownedNFTs.back")
    }
}

#Preview("My NFTs — Light") {
    NavigationStack {
        OwnedNFTsView(viewModel: OwnedNFTsViewModel(items: OwnedNFTFixtures.preview))
    }
}

#Preview("My NFTs — Dark") {
    NavigationStack {
        OwnedNFTsView(viewModel: OwnedNFTsViewModel(items: OwnedNFTFixtures.preview))
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty — Light") {
    NavigationStack {
        OwnedNFTsView(viewModel: OwnedNFTsViewModel(items: []))
    }
}

#Preview("Empty — Dark") {
    NavigationStack {
        OwnedNFTsView(viewModel: OwnedNFTsViewModel(items: []))
    }
    .preferredColorScheme(.dark)
}
