//
//  MockNetworkClient.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 08.11.2026.
//

import Foundation
@testable import iOS_FakeNFT_Extended

final class MockNetworkClient: NetworkClient {

    var dataResult: Result<Data, Error> = .success(Data())
    var decodedResult: Result<Any, Error> = .success(Data())
    var receivedRequest: NetworkRequest?

    func send(request: NetworkRequest) async throws -> Data {
        receivedRequest = request
        return try dataResult.get()
    }

    func send<T: Decodable>(request: NetworkRequest) async throws -> T {
        receivedRequest = request
        let result = try decodedResult.get()

        guard let value = result as? T else {
            throw NetworkClientError.parsingError
        }

        return value
    }
}
