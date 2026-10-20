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
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.primary)
                
                Text(totalPrice)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.green)
            }
            
            Button(action: onPay) {
                Text("К оплате")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        .black,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                topTrailingRadius: 12
            )
            .fill(Color(uiColor: .systemGroupedBackground))
        }
    }
}

#Preview {
    CartBottomPaymentView(
        itemCount: 3,
        totalPrice: "5,34 ETH",
        onPay: {
            print("Переход к оплате")
        }
    )
}
