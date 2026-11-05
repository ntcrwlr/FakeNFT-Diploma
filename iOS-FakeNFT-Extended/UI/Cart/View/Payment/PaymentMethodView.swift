//
//  PaymentMethodView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import SwiftUI

struct PaymentMethodView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCurrency: String?
    @State private var showUserAgreement = false

    private let columns = [
        GridItem(.flexible(), spacing: 7),
        GridItem(.flexible(), spacing: 7)
    ]

    private let currencies = CurrencyMockData.currencies

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 7) {
                        ForEach(currencies, id: \.shortName) { currency in
                            CryptoCurrencyCell(
                                imageName: currency.imageName,
                                name: currency.name,
                                shortName: currency.shortName,
                                isSelected: selectedCurrency == currency.shortName
                            )
                            .onTapGesture {
                                selectedCurrency = currency.shortName
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 160)
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Совершая покупку, вы соглашаетесь с условиями")
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)

                        Button {
                            showUserAgreement = true
                        } label: {
                            Text("Пользовательского соглашения")
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.blue)
                    }

                    Button {
                     
                    } label: {
                        Text("Оплатить")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                selectedCurrency == nil
                                    ? Color.gray
                                    : Color.black
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(selectedCurrency == nil)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 16)
                .background(
                    Color(uiColor: .systemBackground)
                        .shadow(
                            color: Color.black.opacity(0.05),
                            radius: 10,
                            y: -5
                        )
                )
            }
            .navigationTitle("Выберите способ оплаты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showUserAgreement) {
                UserAgreementView()
            }
        }
    }
}

#Preview {
    PaymentMethodView()
}
