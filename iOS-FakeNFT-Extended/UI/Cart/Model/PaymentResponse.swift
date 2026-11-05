//
//  PaymentResponse.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import Foundation

struct PaymentResponse: Decodable {
    let success: Bool
    let orderId: String
    let id: String
}
