import Foundation

struct NftCollection: Decodable, Sendable, Identifiable {
    /// Уникальный идентификатор коллекции.
    let id: String

    /// Название коллекции.
    let name: String

    /// Ссылка на обложку коллекции.
    let cover: String

    /// Описание коллекции.
    let description: String

    /// Ссылка на сайт автора коллекции.
    let author: String

    /// Идентификаторы NFT, входящих в коллекцию.
    let nfts: [String]
}
