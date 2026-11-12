//
//  WebView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        
    }
}
