//
//  CartBottomPaymentView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 20.10.2026.
//

import SwiftUI

struct CartBottomPaymentView: View {
    let itemCount: Int
    let totalPrice: String
    let onPay: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(itemCount) NFT")
                    .font(Font(UIFont.caption1))
                    .foregroundStyle(.primary)
                
                Text(totalPrice)
                    .font(Font(UIFont.bodyBold))
                    .foregroundStyle(.green)
            }
            
            Button(action: onPay) {
                Text("К оплате")
                    .font(Font(UIFont.bodyBold))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Color(uiColor: .label),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                topTrailingRadius: 12
            )
            .fill(Color(.lightGrey))
        }
    }
}

#Preview {
    CartBottomPaymentView(
        itemCount: 3,
        totalPrice: "5,34 ETH",
        onPay: {
            
        }
    )
}
