//
//  MockNftService.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 08.11.2026.
//

import Foundation
@testable import iOS_FakeNFT_Extended

struct MockNftService: NftService {
    var results: [String: Result<Nft, Error>]

    func loadNft(id: String) async throws -> Nft {
        guard let result = results[id] else {
            throw NSError(domain: "Test", code: 1)
        }

        return try result.get()
    }
}
