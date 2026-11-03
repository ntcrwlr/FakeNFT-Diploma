import Foundation

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
