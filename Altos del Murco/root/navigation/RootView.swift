//
//  RootView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct RootView<Home: View>: View {
    @ObservedObject var viewModel: AppSessionViewModel
    let home: () -> Home

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                SessionLoadingView()
                    .transition(.opacity)

            case .signedOut:
                home()
                    .transition(.opacity)

            case .needsProfile:
                home()
                    .transition(.opacity)

            case .authenticated:
                home()
                    .transition(.opacity)

            case .error(let message):
                SessionErrorView(
                    message: message,
                    retryAction: {
                        Task { await viewModel.bootstrap() }
                    },
                    signOutAction: {
                        viewModel.signOut()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.screenKey)
    }
}

private struct SessionLoadingView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: .restaurant, scheme: colorScheme)

        ZStack {
            BrandScreenBackground(theme: .restaurant)

            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.accentColor.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                ProgressView()

                Text("Altos del Murco")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text("Preparando la experiencia...")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
            }
            .frame(maxWidth: 360)
            .appCardStyle(.restaurant, emphasized: false)
            .padding(24)
        }
    }
}

private struct SessionErrorView: View {
    let message: String
    let retryAction: () -> Void
    let signOutAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: .neutral, scheme: colorScheme)

        ZStack {
            BrandScreenBackground(theme: .neutral)

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(palette.destructive.opacity(colorScheme == .dark ? 0.22 : 0.12))
                        .frame(width: 72, height: 72)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(palette.destructive)
                }

                VStack(spacing: 8) {
                    Text("No pudimos preparar la sesión")
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button(action: retryAction) {
                        Label("Intentar nuevamente", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrandPrimaryButtonStyle(theme: .neutral))

                    Button(action: signOutAction) {
                        Text("Cerrar sesión")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrandSecondaryButtonStyle(theme: .neutral))
                }
            }
            .frame(maxWidth: 380)
            .appCardStyle(.neutral)
            .padding(24)
        }
    }
}
