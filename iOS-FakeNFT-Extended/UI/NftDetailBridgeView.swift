import SwiftUI

struct NftDetailBridgeView: UIViewControllerRepresentable {
    typealias UIViewControllerType = NftDetailViewController

    let nftId: String
    @Environment(ServicesAssembly.self) var servicesAssembly

    func makeUIViewController(context: Context) -> NftDetailViewController {
        let assembly = NftDetailAssembly(servicesAssembler: servicesAssembly)
        let nftInput = NftDetailInput(id: nftId)
        let nftViewController = assembly.build(with: nftInput) as! NftDetailViewController
        return nftViewController
    }

    func updateUIViewController(_ uiViewController: NftDetailViewController, context: Context) {}
}
