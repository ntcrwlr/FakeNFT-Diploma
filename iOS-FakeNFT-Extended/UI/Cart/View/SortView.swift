//
//  SortView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 28.10.2026.
//

import SwiftUI

struct SortView: View {
    let onSelect: (CartSortOption) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                Text("Сортировка")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                
                sortButton("По цене", option: .price)
                sortButton("По рейтингу", option: .rating)
                sortButton("По названию", option: .name)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            CloseSortButton(action: onClose)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color.clear)
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }
    
    private func sortButton(
        _ title: String,
        option: CartSortOption
    ) -> some View {
        Button {
            onSelect(option)
            onClose()
        } label: {
            Text(title)
                .font(.system(size: 20))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 0.5)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct CloseSortButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Закрыть")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SortView(
        onSelect: { option in
            print("Выбрана сортировка: \(option)")
        },
        onClose: {}
    )
}

