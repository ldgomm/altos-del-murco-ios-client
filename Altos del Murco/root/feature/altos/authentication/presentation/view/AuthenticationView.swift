//
//  uthenticationView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @ObservedObject var viewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        ZStack {
            BrandScreenBackground(theme: .neutral)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 24)

                    headerSection
                    featureCard
                    signInCard

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .tint(palette.primary)
    }
    
    private var headerSection: some View {
        VStack(spacing: 18) {
//            Image("logo")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 110, height: 110)

            ZStack {
                Circle()
                    .fill(palette.chipGradient)
                    .frame(width: 96, height: 96)
                
                Circle()
                    .stroke(palette.stroke, lineWidth: 1)
                    .frame(width: 96, height: 96)
                
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(palette.primary)
            }
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.24 : 0.10),
                radius: 16,
                x: 0,
                y: 8
            )
            
            VStack(spacing: 8) {
                Text("Altos del Murco")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                
                Text("Restaurant, adventure and rewards in one account.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            
            HStack(spacing: 10) {
                BrandBadge(theme: .restaurant, title: "Restaurant")
                BrandBadge(theme: .adventure, title: "Adventure")
                BrandBadge(theme: .neutral, title: "Rewards")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Everything in one place",
                subtitle: "Your account connects food, bookings, rewards and personalized offers."
            )
            
            VStack(spacing: 14) {
                FeatureRow(
                    theme: .restaurant,
                    icon: "fork.knife",
                    text: "Restaurant orders and loyalty"
                )
                
                FeatureRow(
                    theme: .neutral,
                    icon: "birthday.cake.fill",
                    text: "Birthday discounts and special promos"
                )
                
                FeatureRow(
                    theme: .adventure,
                    icon: "figure.outdoor.cycle",
                    text: "Adventure bookings in one place"
                )
                
                FeatureRow(
                    theme: .neutral,
                    icon: "lock.shield.fill",
                    text: "Private and secure Apple sign in"
                )
            }
        }
        .appCardStyle(.neutral, emphasized: true)
    }
    
    private var signInCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("Sign in to continue")
                    .font(.title3.bold())
                    .foregroundStyle(palette.textPrimary)
                
                Text("Your profile helps us personalize reservations, discounts and contact details.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.textSecondary)
            }
            
            SignInWithAppleButton(
                onRequest: viewModel.onRequestSignIn,
                onCompletion: viewModel.onCompletionSignIn
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
            
            Text("By continuing, your account will be linked to your Apple sign in.")
                .font(.footnote)
                .foregroundStyle(palette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .appCardStyle(.neutral)
        .padding(.top, 4)
    }
}

private struct FeatureRow: View {
    let theme: AppSectionTheme
    let icon: String
    let text: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            BrandIconBubble(theme: theme, systemImage: icon, size: 42)

            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.textPrimary)

            Spacer()
        }
        .padding(.vertical, 2)
    }
}
