//
//  ProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ProfileViewModel

    private let theme: AppSectionTheme = .neutral

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    init(viewModelFactory: @escaping () -> ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statsSection
                    accountSection
                    preferencesSection
                    socialSection
                    supportSection
                    dangerSection
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Profile")
            .sheet(isPresented: $viewModel.isShowingEditProfile) {
                EditProfileView(
                    viewModelFactory: { viewModel.makeEditProfileViewModel() }
                )
            }
            .sheet(isPresented: $viewModel.isShowingDeleteAccountSheet) {
                DeleteAccountConfirmationView(viewModel: viewModel)
            }
            .alert(item: $viewModel.alertItem) { item in
                Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .appScreenStyle(theme)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(palette.heroGradient)
                        .frame(width: 84, height: 84)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.35), lineWidth: 1)
                        )
                        .shadow(
                            color: palette.shadow.opacity(colorScheme == .dark ? 0.28 : 0.12),
                            radius: 14,
                            x: 0,
                            y: 8
                        )

                    Text(viewModel.displayName.initials)
                        .font(.title.bold())
                        .foregroundStyle(palette.onPrimary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text(viewModel.emailText)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    Label("Member since \(viewModel.memberSinceText)", systemImage: "calendar")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()
            }

            VStack(spacing: 10) {
                infoPill(title: "Phone", value: viewModel.phoneText)
                infoPill(title: "Birthday", value: viewModel.birthdayText)
                infoPill(title: "Address", value: viewModel.addressText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme, emphasized: false)
    }

    private func infoPill(title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(palette.textSecondary)

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(title: "Points", value: "\(viewModel.stats.points)")
            statCard(title: "Orders", value: "\(viewModel.stats.orders)")
            statCard(title: "Bookings", value: "\(viewModel.stats.bookings)")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(palette.textPrimary)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(theme)
    }

    private var accountSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Account")

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
    }

    private var preferencesSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Preferences")

            NavigationLink {
                AppearanceSettingsView(viewModel: viewModel)
            } label: {
                navigationRow(
                    title: "Appearance",
                    subtitle: viewModel.appearanceTitle,
                    systemImage: "circle.lefthalf.filled",
                    tint: .purple
                )
            }
            .buttonStyle(.plain)

            actionRow(
                title: "App Permissions",
                subtitle: "Notifications, location and device settings",
                systemImage: "gearshape.2.fill",
                tint: .gray
            ) {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(settingsURL)
            }
        }
    }

    private var socialSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Social & Visit Us")

            actionRow(
                title: "Instagram",
                subtitle: "@altosdelmurco",
                systemImage: "camera.fill",
                tint: .pink
            ) {
                openURL(AppExternalLinks.instagram)
            }

            actionRow(
                title: "TikTok",
                subtitle: "@altosdelmurco",
                systemImage: "music.note.tv",
                tint: .black
            ) {
                openURL(AppExternalLinks.tiktok)
            }

            actionRow(
                title: "Facebook",
                subtitle: "Follow our updates and promos",
                systemImage: "f.cursive.circle.fill",
                tint: .blue
            ) {
                openURL(AppExternalLinks.facebook)
            }

            actionRow(
                title: "WhatsApp",
                subtitle: "Contact us directly",
                systemImage: "message.fill",
                tint: .green
            ) {
                openURL(AppExternalLinks.whatsapp)
            }

            actionRow(
                title: "Open in Maps",
                subtitle: "Navigate to Altos del Murco",
                systemImage: "map.fill",
                tint: .red
            ) {
                openURL(AppExternalLinks.maps)
            }
        }
    }

    private var supportSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Support & Legal")

            actionRow(
                title: "Help & Support",
                subtitle: "Email our support team",
                systemImage: "questionmark.circle.fill",
                tint: .teal
            ) {
                openURL(AppExternalLinks.supportEmail)
            }

            actionRow(
                title: "Privacy Policy",
                subtitle: "Read how your data is used",
                systemImage: "hand.raised.fill",
                tint: .indigo
            ) {
                openURL(AppExternalLinks.privacyPolicy)
            }

            actionRow(
                title: "Terms & Conditions",
                subtitle: "App and service terms",
                systemImage: "doc.text.fill",
                tint: .brown
            ) {
                openURL(AppExternalLinks.terms)
            }
        }
    }

    private var dangerSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Danger Zone")

            actionRow(
                title: "Sign Out",
                subtitle: "Close your current session",
                systemImage: "rectangle.portrait.and.arrow.right",
                tint: .orange
            ) {
                viewModel.signOutTapped()
            }

            actionRow(
                title: "Delete Account",
                subtitle: "Permanently remove your account",
                systemImage: "trash.fill",
                tint: .red
            ) {
                viewModel.askForDeleteAccount()
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 8) {
            Text("Altos del Murco")
                .font(.footnote.bold())
                .foregroundStyle(palette.textPrimary)

            Text(Bundle.main.appVersionDescription)
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        BrandSectionHeader(theme: theme, title: title)
    }

    private func actionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            baseRow(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                tint: tint
            )
        }
        .buttonStyle(.plain)
    }

    private func navigationRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        baseRow(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            tint: tint
        )
    }

    private func baseRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tint.opacity(colorScheme == .dark ? 0.22 : 0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .overlay(
                Circle()
                    .stroke(palette.stroke, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
        }
        .appListRowStyle(theme)
    }
}
