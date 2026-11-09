//
//  CurrencyMockData.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import Foundation

struct CurrencyMockData {
    let imageName: String
    let name: String
    let shortName: String
}

extension CurrencyMockData {
    static let currencies: [CurrencyMockData] = [
        CurrencyMockData(
            imageName: "bitcoin",
            name: "Bitcoin",
            shortName: "BTC"
        ),
        CurrencyMockData(
            imageName: "dogecoin",
            name: "Dogecoin",
            shortName: "DOGE"
        ),
        CurrencyMockData(
            imageName: "tether",
            name: "Tether",
            shortName: "USDT"
        ),
        CurrencyMockData(
            imageName: "apecoin",
            name: "Apecoin",
            shortName: "APE"
        ),
        CurrencyMockData(
            imageName: "solana",
            name: "Solana",
            shortName: "SOL"
        ),
        CurrencyMockData(
            imageName: "ethereum",
            name: "Ethereum",
            shortName: "ETH"
        ),
        CurrencyMockData(
            imageName: "cardano",
            name: "Cardano",
            shortName: "ADA"
        ),
        CurrencyMockData(
            imageName: "shib",
            name: "Shiba Inu",
            shortName: "SHIB"
        )
    ]
}
