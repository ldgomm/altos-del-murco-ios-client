//
//  ProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: ProfileViewModel

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
                .padding()
            }
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
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#8C4B16"), Color(hex: "#C67A30")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 84, height: 84)

                Text(viewModel.displayName.initials)
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }

            Text(viewModel.displayName)
                .font(.title2.bold())

            Text(viewModel.emailText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Label("Member since \(viewModel.memberSinceText)", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            VStack(spacing: 10) {
                infoPill(title: "Phone", value: viewModel.phoneText)
                infoPill(title: "Birthday", value: viewModel.birthdayText)
                infoPill(title: "Address", value: viewModel.addressText)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func infoPill(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
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

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
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

            Text(Bundle.main.appVersionDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline.bold())
            Spacer()
        }
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
                    .fill(tint.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: systemImage)
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}
