//
//  ProtectedAccessRequiredView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 29/4/26.
//

import SwiftUI
import AuthenticationServices

struct ProtectedAccessRequiredView<Content: View>: View {
    let title: String
    let message: String
    let systemImage: String
    let theme: AppSectionTheme
    let onContinueBrowsing: (() -> Void)?
    let content: () -> Content

    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    init(
        title: String,
        message: String,
        systemImage: String = "person.crop.circle.badge.checkmark",
        theme: AppSectionTheme = .neutral,
        onContinueBrowsing: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.theme = theme
        self.onContinueBrowsing = onContinueBrowsing
        self.content = content
    }

    var body: some View {
        Group {
            if sessionViewModel.isAuthenticated {
                content()
            } else {
                signInRequiredBody
            }
        }
    }

    private var signInRequiredBody: some View {
        ZStack {
            BrandScreenBackground(theme: theme)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer(minLength: 28)

                    VStack(spacing: 16) {
                        BrandIconBubble(theme: theme, systemImage: systemImage, size: 68)

                        VStack(spacing: 8) {
                            Text(title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(palette.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 340)
                        }
                    }
                    .appCardStyle(theme, emphasized: true)

                    VStack(spacing: 14) {
                        SignInWithAppleButton(
                            onRequest: sessionViewModel.onRequestSignIn,
                            onCompletion: sessionViewModel.onCompletionSignIn
                        )
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(
                            color: palette.shadow.opacity(colorScheme == .dark ? 0.24 : 0.10),
                            radius: 14,
                            x: 0,
                            y: 8
                        )

                        Text("Solo te pediremos datos personales cuando sean necesarios para crear un pedido, reserva o servicio real.")
                            .font(.footnote)
                            .foregroundStyle(palette.textTertiary)
                            .multilineTextAlignment(.center)

                        if let onContinueBrowsing {
                            Button(action: onContinueBrowsing) {
                                Text("Continuar navegando")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(BrandSecondaryButtonStyle(theme: theme))
                        }
                    }
                    .appCardStyle(theme)

                    VStack(alignment: .leading, spacing: 12) {
                        infoRow(icon: "eye.fill", text: "Puedes ver el menú y catálogo sin iniciar sesión.")
                        infoRow(icon: "cart.fill", text: "Para confirmar un pedido sí necesitamos una cuenta.")
                        infoRow(icon: "person.text.rectangle.fill", text: "La cédula se solicita dentro del pedido o reserva, no al abrir la app.")
                    }
                    .appCardStyle(theme, emphasized: false)

                    Spacer(minLength: 28)
                }
                .padding(20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.primary)
                .frame(width: 22)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

extension ProtectedAccessRequiredView where Content == EmptyView {
    init(
        title: String,
        message: String,
        systemImage: String = "person.crop.circle.badge.checkmark",
        theme: AppSectionTheme = .neutral,
        onContinueBrowsing: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            message: message,
            systemImage: systemImage,
            theme: theme,
            onContinueBrowsing: onContinueBrowsing
        ) {
            EmptyView()
        }
    }
}
