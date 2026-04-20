//
//  ProfileAccountHubView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct ProfileAccountHubView: View {
    @ObservedObject var viewModel: ProfileViewModel

    private let theme: AppSectionTheme = .neutral

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                actionRow(
                    title: "Personal Information",
                    subtitle: "Edit your contact and emergency details",
                    systemImage: "person.text.rectangle"
                ) {
                    viewModel.openEditProfile()
                }

                actionRow(
                    title: "Rewards & Points",
                    subtitle: "\(viewModel.stats.level.title) • \(viewModel.stats.points) points",
                    systemImage: "gift.fill"
                ) { }

                actionRow(
                    title: "Birthday Benefits",
                    subtitle: "Used for special promos and discounts",
                    systemImage: "birthday.cake.fill"
                ) { }

                NavigationLink {
                    AccountActionsView(viewModel: viewModel)
                } label: {
                    row(
                        title: "Account Actions",
                        subtitle: "Sign out and other sensitive account actions",
                        systemImage: "exclamationmark.shield.fill"
                    )
                }
                .buttonStyle(.plain)
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
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            row(title: title, subtitle: subtitle, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func row(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
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
}
