//
//  AccountActionsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import SwiftUI

struct AccountActionsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSignOutDialog = false
    @State private var showDeleteDialog = false

    private let theme: AppSectionTheme = .neutral

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                dangerRow(
                    title: "Sign Out",
                    subtitle: "Close your current session on this device",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    tint: .orange
                ) {
                    showSignOutDialog = true
                }

                dangerRow(
                    title: "Delete Account",
                    subtitle: "Permanently remove your account and profile",
                    systemImage: "trash.fill",
                    tint: .red
                ) {
                    showDeleteDialog = true
                }
            }
            .padding(16)
        }
        .navigationTitle("Account Actions")
        .appScreenStyle(theme)
        .confirmationDialog(
            "Sign out?",
            isPresented: $showSignOutDialog,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                viewModel.signOutTapped()
            }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog(
            "Delete account?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                viewModel.askForDeleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("These actions affect your account and should be confirmed first.")
        }
    }

    private func dangerRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(colorScheme == .dark ? 0.20 : 0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(tint)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(tint.opacity(0.7))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(palette.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
