//
//  ProfileSupportHubView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import SwiftUI

struct ProfileSupportHubView: View {
    @Environment(\.openURL) private var openURL

    private let theme: AppSectionTheme = .neutral

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                supportRow(
                    title: "Help & Support",
                    subtitle: "Email our support team",
                    systemImage: "questionmark.circle.fill",
                    tint: .teal,
                    url: AppExternalLinks.supportEmail
                )

                supportRow(
                    title: "Privacy Policy",
                    subtitle: "Read how your data is used",
                    systemImage: "hand.raised.fill",
                    tint: .indigo,
                    url: AppExternalLinks.privacyPolicy
                )

                supportRow(
                    title: "Terms & Conditions",
                    subtitle: "App and service terms",
                    systemImage: "doc.text.fill",
                    tint: .brown,
                    url: AppExternalLinks.terms
                )
            }
            .padding(16)
        }
        .navigationTitle("Help & Support")
        .appScreenStyle(theme)
    }

    private func supportRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        url: URL
    ) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 14) {
                BrandIconBubble(theme: theme, systemImage: systemImage, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.tertiary)
            }
            .appCardStyle(theme)
        }
        .buttonStyle(.plain)
    }
}
