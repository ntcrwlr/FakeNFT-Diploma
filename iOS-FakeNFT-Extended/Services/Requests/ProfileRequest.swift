import Foundation

struct UpdateProfileLikesRequest: NetworkRequest {
    let ids: [String]

    var endpoint: URL? { ProfileRequest().endpoint }
    var httpMethod: HttpMethod { .put }
    var formFields: [URLQueryItem]? {
        // The API requires the literal "null" to clear likes; an empty value returns HTTP 406.
        [URLQueryItem(name: "likes", value: ids.isEmpty ? "null" : ids.joined(separator: ","))]
    }
}

struct ProfileRequest: NetworkRequest {
    var endpoint: URL? {
        URL(string: "\(RequestConstants.baseURL)/api/v1/profile/1")
    }
}

struct UpdateProfileRequest: NetworkRequest {
    let profile: ProfileUpdate

    var endpoint: URL? { ProfileRequest().endpoint }
    var httpMethod: HttpMethod { .put }

    var formFields: [URLQueryItem]? {
        [
            URLQueryItem(name: "name", value: profile.name),
            URLQueryItem(name: "description", value: profile.description),
            URLQueryItem(name: "avatar", value: profile.avatar),
            URLQueryItem(name: "website", value: profile.website)
        ]
    }
}
