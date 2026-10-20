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
    
    var body: some View {
        HStack(spacing: 20) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: 108, height: 108)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                
                Image("rating\(rating)")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 12)
                    .padding(.top, 4)
                
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
        }
        .frame(height: 140)
    }
}

#Preview {
    CartItemCell(
        image: "april",
        name: "April",
        rating: 1,
        price: "1,78 ETH"
    )
    .padding()
}
