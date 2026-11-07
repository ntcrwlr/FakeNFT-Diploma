//
//  CryptoCurrencyCell.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import SwiftUI

struct CryptoCurrencyCell: View {
    let imageName: String?
    let imageURL: URL?
    let name: String
    let shortName: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 4) {
            Group {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                } else if let imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
            }
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
                    isSelected ? Color.primary : Color.clear,
                    lineWidth: 1.5
                )
        }
    }
}

#Preview {
    CryptoCurrencyCell(
        imageName: "bitcoin",
        imageURL: nil,
        name: "Bitcoin",
        shortName: "BTC",
        isSelected: true
    )
}
