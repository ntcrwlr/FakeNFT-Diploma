import Foundation

enum PreviewData {
    static let collections: [NftCollection] = [
        NftCollection(
            id: "peach",
            name: "Peach",
            cover: "",
            description: "",
            author: "",
            nfts: (0..<11).map(String.init)
        ),
        NftCollection(
            id: "blue",
            name: "Blue",
            cover: "",
            description: "",
            author: "",
            nfts: (0..<6).map(String.init)
        ),
        NftCollection(
            id: "brown",
            name: "Brown",
            cover: "",
            description: "",
            author: "",
            nfts: (0..<8).map(String.init)
        )
    ]
}
