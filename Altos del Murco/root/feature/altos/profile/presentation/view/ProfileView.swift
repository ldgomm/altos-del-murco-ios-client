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
                    mainMenuSection
                    socialCompactSection
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
        VStack(spacing: 18) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(palette.heroGradient)
                    .frame(width: 104, height: 104)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.white.opacity(colorScheme == .dark ? 0.10 : 0.32),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: palette.shadow.opacity(colorScheme == .dark ? 0.28 : 0.12),
                        radius: 16,
                        x: 0,
                        y: 10
                    )

                Text(viewModel.displayName.initials)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.onPrimary)

                Button {
                    viewModel.openEditProfile()
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(palette.primary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                }
                .offset(x: 4, y: 4)
            }

            VStack(spacing: 6) {
                Text(viewModel.displayName)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)

                Text(viewModel.emailText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)

                Label("Member since \(viewModel.memberSinceText)", systemImage: "calendar")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.textSecondary)
            }

            HStack(spacing: 10) {
                compactInfoCard(
                    title: "Phone",
                    value: viewModel.phoneText,
                    systemImage: "phone.fill"
                )

                compactInfoCard(
                    title: "Birthday",
                    value: viewModel.birthdayText,
                    systemImage: "birthday.cake.fill"
                )
            }

            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(
                    theme: theme,
                    systemImage: "house.fill",
                    size: 38
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Address")
                        .font(.caption.bold())
                        .foregroundStyle(palette.textSecondary)

                    Text(viewModel.addressText)
                        .font(.subheadline)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(palette.elevatedCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(theme, emphasized: false)
    }
    
    private func compactInfoCard(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)

                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textSecondary)
            }

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
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
        VStack(spacing: 12) {
            HStack {
                Text("Overview")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Spacer()
            }

            HStack(spacing: 12) {
                profileStatCard(
                    title: "Points",
                    value: "\(viewModel.stats.points)",
                    systemImage: "star.fill"
                )

                profileStatCard(
                    title: "Orders",
                    value: "\(viewModel.stats.orders)",
                    systemImage: "fork.knife"
                )

                profileStatCard(
                    title: "Bookings",
                    value: "\(viewModel.stats.bookings)",
                    systemImage: "calendar"
                )
            }
        }
    }
    
    private func profileStatCard(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(palette.chipGradient)
                    .frame(width: 42, height: 42)

                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(palette.primary)
            }

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(palette.textPrimary)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.14 : 0.06),
            radius: 8,
            x: 0,
            y: 4
        )
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
    
    private var mainMenuSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Settings")

            NavigationLink {
                ProfileAccountHubView(viewModel: viewModel)
            } label: {
                navigationRow(
                    title: "Account",
                    subtitle: "Personal information, rewards and birthday benefits",
                    systemImage: "person.crop.circle",
                    tint: .blue
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProfilePreferencesHubView(viewModel: viewModel)
            } label: {
                navigationRow(
                    title: "Preferences",
                    subtitle: "Appearance and app permissions",
                    systemImage: "slider.horizontal.3",
                    tint: .purple
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProfileSupportHubView()
            } label: {
                navigationRow(
                    title: "Help & Support",
                    subtitle: "Support, privacy policy and terms",
                    systemImage: "questionmark.circle",
                    tint: .teal
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var socialCompactSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Social & Visit Us")

            HStack(spacing: 14) {
                socialIconButton(
                    systemImage: "camera.fill",
                    tint: .pink,
                    action: { openURL(AppExternalLinks.instagram) }
                )

                socialIconButton(
                    systemImage: "music.note.tv",
                    tint: .black,
                    action: { openURL(AppExternalLinks.tiktok) }
                )

                socialIconButton(
                    systemImage: "f.cursive.circle.fill",
                    tint: .blue,
                    action: { openURL(AppExternalLinks.facebook) }
                )

                socialIconButton(
                    systemImage: "message.fill",
                    tint: .green,
                    action: { openURL(AppExternalLinks.whatsapp) }
                )

                socialIconButton(
                    systemImage: "map.fill",
                    tint: .red,
                    action: { openURL(AppExternalLinks.maps) }
                )
            }
            .frame(maxWidth: .infinity)
            .appCardStyle(theme)
        }
    }

    private func socialIconButton(
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(tint.opacity(colorScheme == .dark ? 0.22 : 0.14))
                    .frame(width: 54, height: 54)

                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
            }
        }
        .buttonStyle(.plain)
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
            HStack {
                Text("Account Actions")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Spacer()
            }

            Button {
                viewModel.signOutTapped()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(colorScheme == .dark ? 0.20 : 0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sign Out")
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text("Close your current session")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(palette.textTertiary)
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

            Button {
                viewModel.askForDeleteAccount()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.16))
                            .frame(width: 44, height: 44)

                        Image(systemName: "trash.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Delete Account")
                            .font(.headline)
                            .foregroundStyle(.red)

                        Text("Permanently remove your account")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.red.opacity(0.7))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.red.opacity(colorScheme == .dark ? 0.10 : 0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.red.opacity(0.22), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
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
