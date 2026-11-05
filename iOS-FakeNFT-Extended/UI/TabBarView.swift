import SwiftUI

struct TabBarView: View {
    @Environment(ServicesAssembly.self) private var servicesAssembly
    var body: some View {
        TabView {
            TestCatalogView()
                .tabItem {
                    Label(
                        NSLocalizedString("Tab.catalog", comment: ""),
                        systemImage: "square.stack.3d.up.fill"
                    )
                }

            CartView(
                viewModel: CartViewModel(
                    cartService: servicesAssembly.cartService,
                    nftService: servicesAssembly.nftService
                )
            )
            .tabItem {
                Label(
                    "Корзина",
                    systemImage: "cart.fill"
                )
            }
        }
    }
}
