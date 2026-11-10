import Foundation

enum RequestConstants {
    static let baseURL = "https://d5dn3j2ouj72b0ejucbl.apigw.yandexcloud.net"

    static let token: String = {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let dictionary = NSDictionary(contentsOf: url),
            let token = dictionary["token"] as? String
        else {
            return ""
        }
        return token
    }()
}
