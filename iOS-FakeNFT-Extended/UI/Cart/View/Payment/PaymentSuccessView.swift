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

            Image(systemName: "")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Оплата прошла успешно!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                onReturnToCart()
            } label: {
                Text("Вернуться в корзину")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.black)
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
