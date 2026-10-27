//
//  DeleteConfirmationView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 27.10.2026.
//

import SwiftUI

struct DeleteConfirmationView: View {
    let item: CartItem
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if item.imageName.hasPrefix("http"),
                   let url = URL(string: item.imageName) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            placeholder
                        }
                    }
                } else if !item.imageName.isEmpty {
                    Image(item.imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }
            }
            .frame(width: 108, height: 108)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("Вы уверены, что хотите\nудалить объект из корзины?")
                .font(.system(size: 13, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.top, 12)

            HStack(spacing: 8) {
                Button("Удалить", action: onDelete)
                    .font(.system(size: 17, weight: .regular))
                    .frame(width: 127, height: 44)
                    .background(Color.black)
                    .foregroundStyle(.red)
                    .cornerRadius(12)

                Button("Вернуться", action: onCancel)
                    .font(.system(size: 17, weight: .regular))
                    .frame(width: 127, height: 44)
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 20)
        }
        .padding(20)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .padding(.horizontal, 40)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.15))
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        DeleteConfirmationView(
            item: CartItem(
                id: "preview-1",
                imageName: "april",
                name: "April",
                rating: 5,
                price: 1.78
            ),
            onDelete: {},
            onCancel: {}
        )
    }
}
