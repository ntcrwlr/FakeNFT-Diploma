//
//  Currency.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import Foundation

struct Currency: Decodable, Identifiable {
    let id: String
    let title: String
    let name: String
    let image: URL
}
