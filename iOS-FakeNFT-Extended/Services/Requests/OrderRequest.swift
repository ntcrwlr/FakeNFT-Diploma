import Foundation

struct OrderRequest: NetworkRequest {
    var endpoint: URL? {
        URL(string: "\(RequestConstants.baseURL)/api/v1/orders/1")
    }
}

struct UpdateOrderRequest: NetworkRequest {
    let nftIds: Set<String>

    var endpoint: URL? {
        URL(string: "\(RequestConstants.baseURL)/api/v1/orders/1")
    }

    var httpMethod: HttpMethod { .put }

    var contentType: String? { "application/x-www-form-urlencoded" }

    var httpBody: Data? {
        let value = nftIds.isEmpty ? "null" : nftIds.sorted().joined(separator: ",")
        return "nfts=\(value)".data(using: .utf8)
    }
}

struct OrderResponse: Decodable {
    let nfts: [String]?
}
