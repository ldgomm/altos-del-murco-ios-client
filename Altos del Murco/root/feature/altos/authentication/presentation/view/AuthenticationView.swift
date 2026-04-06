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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#1E1B18"),
                    Color(hex: "#402617"),
                    Color(hex: "#8C4B16")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 32)

//                    Image("logo")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 130, height: 130)
//                        .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 6)

                    VStack(spacing: 8) {
                        Text("Altos del Murco")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Restaurant, adventure and rewards in one account.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.82))
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "fork.knife", text: "Restaurant orders and loyalty")
                        FeatureRow(icon: "birthday.cake.fill", text: "Birthday discounts and special promos")
                        FeatureRow(icon: "figure.outdoor.cycle", text: "Adventure bookings in one place")
                        FeatureRow(icon: "lock.shield.fill", text: "Private and secure Apple sign in")
                    }
                    .padding(20)
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        Text("Sign in to continue")
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        Text("Your profile helps us personalize reservations, discounts and contact details.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)

                    SignInWithAppleButton(
                        onRequest: viewModel.onRequestSignIn,
                        onCompletion: viewModel.onCompletionSignIn
                    )
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 56)
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)

                    Text("By continuing, your account will be linked to your Apple sign in.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 24)
                }
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(.white.opacity(0.18))
                .clipShape(Circle())
                .foregroundStyle(.white)

            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.95))

            Spacer()
        }
    }
}
