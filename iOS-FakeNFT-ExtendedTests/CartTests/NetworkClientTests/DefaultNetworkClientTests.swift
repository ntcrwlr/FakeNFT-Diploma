//
//  DefaultNetworkClientTests.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 08.11.2026.
//

import XCTest
@testable import iOS_FakeNFT_Extended

final class DefaultNetworkClientTests: XCTestCase {

    // MARK: - Setup

    private func makeNetworkClient() -> DefaultNetworkClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]

        let session = URLSession(configuration: configuration)

        return DefaultNetworkClient(session: session)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Successful Request

    func testSendReturnsDataOnSuccess() async throws {
        let expectedData = Data("Test response".utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, expectedData)
        }

        let client = makeNetworkClient()
        let data = try await client.send(request: CurrenciesRequest())

        XCTAssertEqual(data, expectedData)
    }

    // MARK: - HTTP Error

    func testSendThrowsHTTPStatusCodeError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, Data())
        }

        let client = makeNetworkClient()

        do {
            let _: Data = try await client.send(request: CurrenciesRequest())
            XCTFail("Expected HTTP status code error")
        } catch let error as NetworkClientError {
            guard case .httpStatusCode(500) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Decoding Error

    func testSendThrowsParsingError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, Data("invalid json".utf8))
        }

        let client = makeNetworkClient()

        do {
            let _: TestResponse = try await client.send(request: CurrenciesRequest())
            XCTFail("Expected parsing error")
        } catch let error as NetworkClientError {
            guard case .parsingError = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Invalid Request

    func testSendThrowsIncorrectRequestForEmptyEndpoint() async {
        let client = makeNetworkClient()

        do {
            let _: Data = try await client.send(request: InvalidNetworkRequest())
            XCTFail("Expected incorrect request error")
        } catch let error as NetworkClientError {
            guard case .incorrectRequest("Empty endpoint") = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Successful Decoding

    func testSendDecodesResponse() async throws {
        let expectedResponse = TestResponse(id: 1, name: "Test NFT")
        let responseData = try JSONEncoder().encode(expectedResponse)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, responseData)
        }

        let client = makeNetworkClient()
        let result: TestResponse = try await client.send(request: CurrenciesRequest())

        XCTAssertEqual(result, expectedResponse)
    }
}

// MARK: - Test Models

private struct TestResponse: Codable, Equatable {
    let id: Int
    let name: String
}

private struct InvalidNetworkRequest: NetworkRequest {
    var endpoint: URL? { nil }
}
