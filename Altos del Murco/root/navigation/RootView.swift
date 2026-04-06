//
//  RootView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

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
                AuthenticationView(viewModel: viewModel)
                    .transition(.opacity)

            case .needsProfile(let user, let existingProfile):
                CompleteProfileView {
                    viewModel.makeCompleteProfileViewModel(
                        user: user,
                        existingProfile: existingProfile
                    )
                }
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

            VStack(spacing: 24) {
                VStack(spacing: 18) {
                    BrandIconBubble(
                        theme: .restaurant,
                        systemImage: "flame.fill",
                        size: 72
                    )
                    
                    VStack(spacing: 8) {
                        Text("Altos del Murco")
                            .font(.title.bold())
                            .foregroundStyle(palette.textPrimary)
                        
                        Text("Loading your experience...")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
                
                VStack(spacing: 14) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(palette.primary)
                    
                    Text("Please wait a moment")
                        .font(.footnote)
                        .foregroundStyle(palette.textTertiary)
                }
            }
            .frame(maxWidth: 360)
            .appCardStyle(.restaurant, emphasized: true)
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

                VStack(spacing: 10) {
                    Text("Something went wrong")
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(palette.textSecondary)
                }

                VStack(spacing: 12) {
                    Button(action: retryAction) {
                        Text("Try again")
                    }
                    .buttonStyle(BrandPrimaryButtonStyle(theme: .neutral))

                    Button(action: signOutAction) {
                        Text("Sign out")
                    }
                    .buttonStyle(BrandSecondaryButtonStyle(theme: .neutral))
                }
            }
            .frame(maxWidth: 420)
            .appCardStyle(.neutral, emphasized: true)
            .padding(24)
        }
    }
}
