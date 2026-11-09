import Foundation

struct ProfileLikesRequest: NetworkRequest {
    var endpoint: URL? {
        URL(string: "\(RequestConstants.baseURL)/api/v1/profile/1")
    }
}

struct ProfileLikesResponse: Decodable {
    let likes: [String]?
}
