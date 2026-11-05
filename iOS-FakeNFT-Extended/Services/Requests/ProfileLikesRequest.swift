import Foundation

struct ProfileLikesRequest: NetworkRequest {
    var endpoint: URL? {
        URL(string: "\(RequestConstants.baseURL)/api/v1/profile/1")
    }
}

struct UpdateProfileLikesRequest: NetworkRequest {
    let likes: Set<String>

    var endpoint: URL? {
        URL(string: "\(RequestConstants.baseURL)/api/v1/profile/1")
    }

    var httpMethod: HttpMethod { .put }

    var contentType: String? { "application/x-www-form-urlencoded" }

    var httpBody: Data? {
        let value = likes.isEmpty ? "null" : likes.sorted().joined(separator: ",")
        return "likes=\(value)".data(using: .utf8)
    }
}

struct ProfileLikesResponse: Decodable {
    let likes: [String]?
}
