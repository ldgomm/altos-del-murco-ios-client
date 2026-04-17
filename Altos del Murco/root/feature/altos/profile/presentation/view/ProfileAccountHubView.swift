//
//  ProfileAccountHubView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import SwiftUI

struct ProfileAccountHubView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    private let theme: AppSectionTheme = .neutral

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                actionRow(
                    title: "Personal Information",
                    subtitle: "Edit your contact and emergency details",
                    systemImage: "person.text.rectangle",
                    tint: .blue
                ) {
                    viewModel.openEditProfile()
                }

                actionRow(
                    title: "Rewards & Points",
                    subtitle: "Your loyalty history and benefits",
                    systemImage: "gift.fill",
                    tint: .orange
                ) { }

                actionRow(
                    title: "Birthday Benefits",
                    subtitle: "Used for special promos and discounts",
                    systemImage: "birthday.cake.fill",
                    tint: .pink
                ) { }
            }
            .padding(16)
        }
        .navigationTitle("Account")
        .appScreenStyle(theme)
    }

    private func actionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .appCardStyle(theme)
        }
        .buttonStyle(.plain)
    }
}
