import SwiftUI
import AppMetricaCore

@main
struct iOS_FakeNFT_ExtendedApp: App {
    
    init() {
        print(
            "AppMetrica key:",
            Bundle.main.object(forInfoDictionaryKey: "APPMETRICA_API_KEY") ?? "КЛЮЧ НЕ НАЙДЕН"
        )
        guard let apiKey = Bundle.main.object(
            forInfoDictionaryKey: "APPMETRICA_API_KEY"
        ) as? String,
              let configuration = AppMetricaConfiguration(apiKey: apiKey) else {
            return
        }
        
        AppMetrica.activate(with: configuration)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(ServicesAssembly(networkClient: DefaultNetworkClient(), nftStorage: NftStorageImpl()))
        }
    }
}
