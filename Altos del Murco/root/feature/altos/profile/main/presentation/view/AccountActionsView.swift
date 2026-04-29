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
                    title: "Cerrar sesión",
                    subtitle: "Cierra tu sesión actual en este dispositivo",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    tint: .orange
                ) {
                    showSignOutDialog = true
                }

                dangerRow(
                    title: "Eliminar cuenta",
                    subtitle: "Elimina permanentemente tu cuenta y perfil",
                    systemImage: "trash.fill",
                    tint: .red
                ) {
                    showDeleteDialog = true
                }
            }
            .padding(16)
        }
        .navigationTitle("Acciones de la cuenta")
        .appScreenStyle(theme)
        .confirmationDialog(
            "¿Cerrar sesión?",
            isPresented: $showSignOutDialog,
            titleVisibility: .visible
        ) {
            Button("Cerrar sesión", role: .destructive) {
                viewModel.signOutTapped()
            }
            Button("Cancelar", role: .cancel) { }
        }
        .confirmationDialog(
            "¿Eliminar cuenta?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Eliminar cuenta", role: .destructive) {
                viewModel.askForDeleteAccount()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Estas acciones afectan tu cuenta y deben confirmarse primero.")
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
