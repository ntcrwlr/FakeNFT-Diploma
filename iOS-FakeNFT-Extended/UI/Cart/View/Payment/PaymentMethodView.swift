//
//  PaymentMethodView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import SwiftUI

struct PaymentMethodView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: PaymentMethodViewModel
    @State private var showUserAgreement = false
    @State private var showPaymentError = false

    private let columns = [
        GridItem(.flexible(), spacing: 7),
        GridItem(.flexible(), spacing: 7)
    ]

    init(viewModel: PaymentMethodViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 7) {
                        if viewModel.isLoading {
                            ProgressView()
                                .gridCellColumns(2)
                        } else if !viewModel.currencies.isEmpty {
                            ForEach(viewModel.currencies) { currency in
                                CryptoCurrencyCell(
                                    imageName: nil,
                                    imageURL: currency.imageURL,
                                    name: currency.title,
                                    shortName: currency.name,
                                    isSelected: viewModel.selectedCurrencyID == currency.id
                                )
                                .onTapGesture {
                                    viewModel.selectCurrency(id: currency.id)
                                }
                            }
                        } else {
                            ForEach(
                                viewModel.mockCurrencies,
                                id: \.shortName
                            ) { currency in
                                CryptoCurrencyCell(
                                    imageName: currency.imageName,
                                    imageURL: nil,
                                    name: currency.name,
                                    shortName: currency.shortName,
                                    isSelected: viewModel.selectedCurrencyID == currency.shortName
                                )
                                .onTapGesture {
                                    viewModel.selectCurrency(id: currency.shortName)
                                }
                            }
                        }
                    }
                    .padding([.horizontal, .top], 16)
                    .padding(.bottom, 160)
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Payment.terms.prefix")
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)

                        Button {
                            showUserAgreement = true
                        } label: {
                            Text("Payment.terms.link")
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.blue)
                    }

                    Button {
                        Task {
                            await viewModel.pay()
                        }
                    } label: {
                        Group {
                            if viewModel.isPaying {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Payment.pay")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color(uiColor: .systemBackground))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            viewModel.selectedCurrencyID == nil || viewModel.isPaying
                            ? Color.gray
                            : Color.primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(
                        viewModel.selectedCurrencyID == nil || viewModel.isPaying
                    )
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
            .navigationTitle("Payment.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: AppImages.chevronLeft)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showUserAgreement) {
                UserAgreementView()
            }
            .alert("Payment.error", isPresented: $showPaymentError) {
                Button("Cart.cancel", role: .cancel) {}
                Button("Payment.retry") {
                    Task {
                        await viewModel.pay()
                    }
                }
            }
            .onChange(of: viewModel.paymentError) { _, error in
                showPaymentError = error != nil
            }
            .task {
                await viewModel.loadCurrencies()
            }
        }
    }
}

#Preview {
    PaymentMethodView(
        viewModel: PaymentMethodViewModel(
            currenciesService: PreviewCurrenciesService(),
            paymentService: PreviewPaymentService()
        )
    )
}

private struct PreviewCurrenciesService: CurrenciesService {
    func loadCurrencies() async throws -> [Currency] {
        []
    }
}

private struct PreviewPaymentService: PaymentService {
    func pay(currencyID: String) async throws -> PaymentResponse {
        PaymentResponse(
            success: true,
            orderId: "1",
            id: "1"
        )
    }
}
