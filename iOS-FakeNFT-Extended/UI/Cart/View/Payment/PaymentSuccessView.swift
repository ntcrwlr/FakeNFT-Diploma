//
//  PaymentSuccessView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import SwiftUI

struct PaymentSuccessView: View {

    let onReturnToCart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(.catStub)
                .resizable()
                .scaledToFit()
                .frame(width: 278, height: 278)

            Text("Payment.success")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Spacer()

            Button {
                onReturnToCart()
            } label: {
                Text("Payment.success.back")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.top, 40)
    }
}

#Preview {
    PaymentSuccessView(
        onReturnToCart: {}
    )
}
