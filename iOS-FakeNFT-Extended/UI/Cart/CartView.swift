//
//  CartView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 20.10.2026.
//

import SwiftUI

struct CartView: View {
    private let items = ["April", "Greena", "Spring"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items, id: \.self) { item in
                    Text(item)
                }
            }
            .listStyle(.plain)
        }
    }
}

#Preview {
    CartView()
}
