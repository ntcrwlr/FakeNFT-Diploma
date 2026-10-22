//
//  EmptyCartView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 22.10.2026.
//

import SwiftUI

struct EmptyCartView: View {
    var body: some View {
        VStack {
           Text("Корзина пуста")
                .font(.system(size: 17, weight: .bold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyCartView()
}
