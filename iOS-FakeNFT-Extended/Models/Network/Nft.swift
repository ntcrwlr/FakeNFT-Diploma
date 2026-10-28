import Foundation

struct Nft: Decodable, Sendable {
    /// Уникальный идентификатор NFT.
    let id: String

    /// Название NFT.
    let name: String

    /// Ссылки на изображения NFT.
    let images: [URL]

    /// Рейтинг NFT. Сервер отдаёт значение от 0 до 10.
    let rating: Int

    /// Цена NFT в ETH.
    let price: Double
}
