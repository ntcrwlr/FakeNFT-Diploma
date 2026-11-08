//
//  CartView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 20.10.2026.
//

import SwiftUI
import ProgressHUD

struct CartView: View {
    @Environment(ServicesAssembly.self) private var servicesAssembly
    @State private var viewModel: CartViewModel
    @State private var showErrorAlert = false
    @State private var selectedItem: CartItem?
    @State private var showDeleteConfirmation = false
    @State private var showSortDialog = false
    @State private var showPaymentMethod = false
    
    init(viewModel: CartViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    private var items: [CartItem] {
        viewModel.items
    }
    
    private var totalPrice: String {
        formatPrice(items.reduce(0) { $0 + $1.price })
    }
    
    private func formatPrice(_ price: Double) -> String {
        "\(String(format: "%.2f", price).replacingOccurrences(of: ".", with: ",")) ETH"
    }
    
    @ViewBuilder
    private var content: some View {
        if items.isEmpty && !viewModel.isLoading {
            EmptyCartView()
                .refreshable {
                    await viewModel.loadCart()
                }
        } else {
            List {
                ForEach(items) { item in
                    CartItemCell(
                        image: item.imageName,
                        name: item.name,
                        rating: item.rating,
                        price: formatPrice(item.price),
                        onDelete: {
                            selectedItem = item
                            showDeleteConfirmation = true
                        }
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
            .refreshable {
                await viewModel.loadCart()
            }
        }
    }
    
    @ViewBuilder
    private var deleteOverlay: some View {
        if showDeleteConfirmation, let item = selectedItem {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Color(.blurOverlay)
                }
                .ignoresSafeArea()
                .overlay {
                    DeleteConfirmationView(
                        item: item,
                        onDelete: {
                            Task {
                                await viewModel.removeItem(item)
                                selectedItem = nil
                                showDeleteConfirmation = false
                            }
                        },
                        onCancel: {
                            showDeleteConfirmation = false
                            selectedItem = nil
                        }
                    )
                }
        }
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button {
                        showSortDialog = true
                    } label: {
                        Image(.sort)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 42, height: 42)
                            .colorMultiply(Color(uiColor: .label))
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    CartBottomPaymentView(
                        itemCount: items.count,
                        totalPrice: totalPrice,
                        onPay: {
                            showPaymentMethod = true
                        }
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
                .alert("Error.title", isPresented: $showErrorAlert) {
                    Button("Error.repeat") {
                        Task {
                            await viewModel.loadCart()
                        }
                    }
                    Button("Cart.cancel", role: .cancel) {}
                } message: {
                    Text(
                        viewModel.errorMessage
                        ?? String(localized: "Error.unknown")
                    )
                }
                .onChange(of: viewModel.errorMessage) { _, errorMessage in
                    showErrorAlert = errorMessage != nil
                }
        }
        .statusBarHidden(showDeleteConfirmation)
        .toolbar(showDeleteConfirmation ? .hidden : .visible, for: .tabBar)
        .overlay {
            deleteOverlay
        }
        .sheet(isPresented: $showSortDialog) {
            SortView(
                onSelect: { option in
                    viewModel.sortItems(by: option)
                },
                onClose: {
                    showSortDialog = false
                }
            )
        }
        .fullScreenCover(isPresented: $showPaymentMethod) {
            PaymentFlowView(
                currenciesService: servicesAssembly.currenciesService,
                paymentService: servicesAssembly.paymentService,
                onPaymentSuccess: { isMockPayment in
                    await viewModel.clearCart(
                        isMockPayment: isMockPayment
                    )
                }
            )
        }
    }
}
