//
//  CartView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 20.10.2026.
//

import SwiftUI

struct CartView: View {
    @State private var items = [
        CartItem(id: "93", image: "april", name: "April", rating: 1, price: 1.78),
        CartItem(id: "94", image: "greena", name: "Greena", rating: 3, price: 1.78),
        CartItem(id: "95", image: "spring", name: "Spring", rating: 5, price: 1.78)
    ]
    
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
        }
    }
}

#Preview {
    CartView()
}

