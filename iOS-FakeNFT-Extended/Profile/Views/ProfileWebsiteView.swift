import SwiftUI
import WebKit

struct ProfileWebsiteView: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL

    var body: some View {
        WebsiteWebView(url: url)
            .accessibilityIdentifier("profile.website.webView")
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                    }
                    .tint(Color(uiColor: .profileForeground))
                    .accessibilityLabel("Назад")
                    .accessibilityIdentifier("profile.website.back")
                }
            }
    }
}

private struct WebsiteWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
