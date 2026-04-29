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
                    title: "Ayuda y soporte",
                    subtitle: "Escribe a nuestro equipo de soporte",
                    systemImage: "questionmark.circle.fill",
                    tint: .teal,
                    url: AppExternalLinks.supportEmail
                )

                supportRow(
                    title: "Política de privacidad",
                    subtitle: "Lee cómo se usan tus datos",
                    systemImage: "hand.raised.fill",
                    tint: .indigo,
                    url: AppExternalLinks.privacyPolicy
                )

                supportRow(
                    title: "Términos y condiciones",
                    subtitle: "Términos de la app y del servicio",
                    systemImage: "doc.text.fill",
                    tint: .brown,
                    url: AppExternalLinks.terms
                )
            }
            .padding(16)
        }
        .navigationTitle("Ayuda y soporte")
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
