//
//  CartView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 20.10.2026.
//

import SwiftUI
import ProgressHUD

struct CartView: View {
    @State private var viewModel: CartViewModel
    @State private var showErrorAlert = false

    init(viewModel: CartViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var items: [CartItem] {
        viewModel.items
    }

    private var totalPrice: String {
        "\(String(format: "%.2f", items.reduce(0) { $0 + $1.price }).replacingOccurrences(of: ".", with: ",")) ETH"
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    CartItemCell(
                        image: item.image,
                        name: item.name,
                        rating: item.rating,
                        price: "\(String(format: "%.2f", item.price).replacingOccurrences(of: ".", with: ",")) ETH",
                        onDelete: {}
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets(
                            top: 0,
                            leading: 16,
                            bottom: 0,
                            trailing: 16
                        )
                    )
                }
            }
            .listStyle(.plain)
            .padding(.top, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Image("sort")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.plain)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CartBottomPaymentView(
                    itemCount: items.count,
                    totalPrice: totalPrice,
                    onPay: {}
                )
            }
            .task {
                await viewModel.loadCart()
            }
            .onChange(of: viewModel.isLoading) { _, isLoading in
                if isLoading {
                    ProgressHUD.animate(interaction: false)
                } else {
                    ProgressHUD.dismiss()
                }
            }
            .alert("Ошибка", isPresented: $showErrorAlert) {
                Button("Повторить") {
                    Task {
                        await viewModel.loadCart()
                    }
                }

                Button("Отмена", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Не удалось загрузить корзину")
            }
            .onChange(of: viewModel.errorMessage) { _, errorMessage in
                showErrorAlert = errorMessage != nil
            }
        }
    }
}

#Preview {
    CartView(
        viewModel: CartViewModel(
            cartService: PreviewCartService(),
            nftService: PreviewNftService()
        )
    )
}
