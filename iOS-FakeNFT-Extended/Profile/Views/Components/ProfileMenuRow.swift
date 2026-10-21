import SwiftUI

struct ProfileMenuRow: View {
    let title: String
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("\(title)  (\(count))")
                    .font(.system(.body, weight: .bold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(count)")
    }
}

#Preview("Profile Menu Row", traits: .sizeThatFitsLayout) {
    ProfileMenuRow(title: "Мои NFT", count: 12, action: {})
        .padding(.horizontal, 16)
}
