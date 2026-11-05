//
//  CartItemCell.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 20.10.2026.
//

import SwiftUI

struct CartItemCell: View {
    let image: String
    let name: String
    let rating: Int
    let price: String
    let onDelete: () -> Void
    
    private var ratingView: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(star <= rating ? .yellow : .lightGrey)
            }
        }
        .padding(.top, 4)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            Group {
                if image.hasPrefix("http://") || image.hasPrefix("https://") {
                    AsyncImage(url: URL(string: image)) { phase in
                        if let loadedImage = phase.image {
                            loadedImage
                                .resizable()
                                .scaledToFill()
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.15))
                        }
                    }
                } else if !image.isEmpty {
                    Image(image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.15))
                }
            }
            .frame(width: 108, height: 108)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                
                ratingView
                
                Text("Цена")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                
                Text(price)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
            
            Button(action: onDelete) {
                Image(.cart)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.primary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(height: 140)
    }
}

#Preview {
    CartItemCell(
        image: "april",
        name: "April",
        rating: 1,
        price: "1,78 ETH",
        onDelete: {}
    )
    .padding()
}
