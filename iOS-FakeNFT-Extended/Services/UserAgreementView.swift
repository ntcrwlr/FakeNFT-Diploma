//
//  UserAgreementView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import SwiftUI

struct UserAgreementView: View {
    private let url = URL(
        string: "https://yandex.ru/legal/practicum_termsofuse"
    )!

    var body: some View {
        NavigationStack {
            WebView(url: url)
                .navigationTitle("Пользовательское соглашение")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
