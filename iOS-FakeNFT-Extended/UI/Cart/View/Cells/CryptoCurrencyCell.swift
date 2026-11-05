//
//  CryptoCurrencyCell.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import SwiftUI

struct CryptoCurrencyCell: View {
    let imageName: String
    let name: String
    let shortName: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.primary)

                Text(shortName)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.green)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 168, height: 46)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.black : Color.clear,
                    lineWidth: 1.5
                )
        }
    }
}

#Preview {
    CryptoCurrencyCell(
        imageName: "bitcoin",
        name: "Bitcoin",
        shortName: "BTC",
        isSelected: true
    )
}
