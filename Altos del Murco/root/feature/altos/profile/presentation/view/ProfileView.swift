//
//  ProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import PhotosUI
import SwiftUI

struct ProfileView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ProfileViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?

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
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Perfil")
            .appScreenStyle(theme)
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
                    dismissButton: .default(Text("Aceptar"))
                )
            }
            .onAppear {
                viewModel.onAppear()
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }

                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            viewModel.uploadProfileImage(data: data)
                        }
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .bottomTrailing) {
                avatarView

                HStack(spacing: 10) {
                    if viewModel.hasProfileImage {
                        Button {
                            viewModel.removeProfileImage()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Circle().fill(.red))
                        }
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "camera.fill")
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

                Label("Miembro desde \(viewModel.memberSinceText)", systemImage: "calendar")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.textSecondary)
            }

            HStack(spacing: 10) {
                compactInfoCard(
                    title: "Teléfono",
                    value: viewModel.phoneText,
                    systemImage: "phone.fill"
                )

                compactInfoCard(
                    title: "Cumpleaños",
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
                    Text("Dirección")
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

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(palette.heroGradient)
                .frame(width: 112, height: 112)
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

            if let avatarImage = viewModel.avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 112, height: 112)
                    .clipShape(Circle())
            } else {
                Text(viewModel.displayName.initials)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.onPrimary)
            }

            if viewModel.isUploadingProfileImage {
                Circle()
                    .fill(.black.opacity(0.35))
                    .frame(width: 112, height: 112)

                ProgressView()
                    .tint(.white)
            }
        }
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

    private var statsSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Resumen")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                Spacer()
            }

            levelCard

            HStack(spacing: 12) {
                profileStatCard(
                    title: "Puntos",
                    value: "\(viewModel.stats.points)",
                    systemImage: "star.fill"
                )

                profileStatCard(
                    title: "Pedidos",
                    value: "\(viewModel.stats.completedOrders)",
                    systemImage: "fork.knife"
                )

                profileStatCard(
                    title: "Reservas",
                    value: "\(viewModel.stats.completedBookings)",
                    systemImage: "calendar"
                )
            }

            HStack(spacing: 12) {
                profileStatCard(
                    title: "Restaurante",
                    value: viewModel.stats.restaurantSpent.priceText,
                    systemImage: "takeoutbag.and.cup.and.straw.fill"
                )

                profileStatCard(
                    title: "Aventura",
                    value: viewModel.stats.adventureSpent.priceText,
                    systemImage: "figure.hiking"
                )
            }
        }
    }

    private var levelCard: some View {
        NavigationLink {
            LoyaltyProgramView(
                currentLevel: viewModel.stats.level,
                totalSpent: viewModel.stats.totalSpent,
                points: viewModel.stats.points,
                completedOrders: viewModel.stats.completedOrders,
                completedBookings: viewModel.stats.completedBookings,
                walletSnapshot: viewModel.stats.wallet
            )
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(palette.chipGradient)
                            .frame(width: 60, height: 60)

                        Image(systemName: viewModel.stats.level.systemImage)
                            .font(.title3.bold())
                            .foregroundStyle(palette.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nivel \(viewModel.stats.level.title)")
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text(viewModel.stats.level.badgeSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)

                        Text("Consumo acumulado: \(viewModel.stats.totalSpent.priceText)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(palette.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(palette.primary)
                }

                Text("Vuelve, acumula y desbloquea descuentos, regalos y premios gratis en platos, jugos, bebidas y postres.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textPrimary)

                if let nextLevel = viewModel.stats.level.nextLevel {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progreso a \(nextLevel.title)")
                                .font(.caption.bold())
                                .foregroundStyle(palette.textSecondary)

                            Spacer()

                            Text("\(Int(LoyaltyLevel.progress(for: viewModel.stats.totalSpent) * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(palette.primary)
                        }

                        ProgressView(value: LoyaltyLevel.progress(for: viewModel.stats.totalSpent))
                            .tint(palette.primary)

                        Text("Te faltan \(viewModel.stats.level.remainingSpend(from: viewModel.stats.totalSpent).priceText) para subir.")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(palette.textSecondary)
                    }
                } else {
                    Label("Ya estás en el nivel más alto", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.primary)
                }

                HStack(spacing: 10) {
                    loyaltyMiniStat(
                        title: "Puntos",
                        value: "\(viewModel.stats.points)",
                        systemImage: "star.fill"
                    )

                    loyaltyMiniStat(
                        title: "Pedidos",
                        value: "\(viewModel.stats.completedOrders)",
                        systemImage: "fork.knife"
                    )

                    loyaltyMiniStat(
                        title: "Reservas",
                        value: "\(viewModel.stats.completedBookings)",
                        systemImage: "calendar"
                    )
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(palette.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.14 : 0.06),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }

    private func loyaltyMiniStat(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.primary)

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)

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

    private var mainMenuSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Configuración")

            NavigationLink {
                ProfileAccountHubView(viewModel: viewModel)
            } label: {
                navigationRow(
                    title: "Cuenta",
                    subtitle: "Información personal, recompensas y acciones de la cuenta",
                    systemImage: "person.crop.circle",
                    tint: .blue
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProfilePreferencesHubView(viewModel: viewModel)
            } label: {
                navigationRow(
                    title: "Preferencias",
                    subtitle: "Apariencia y permisos de la app",
                    systemImage: "slider.horizontal.3",
                    tint: .purple
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProfileSupportHubView()
            } label: {
                navigationRow(
                    title: "Ayuda y soporte",
                    subtitle: "Soporte, política de privacidad y términos",
                    systemImage: "questionmark.circle",
                    tint: .teal
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var socialCompactSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Redes y visítanos")

            HStack(spacing: 14) {
                socialIconButton(
                    systemImage: "camera.fill",
                    action: { openURL(AppExternalLinks.instagram) }
                )

                socialIconButton(
                    systemImage: "music.note.tv",
                    action: { openURL(AppExternalLinks.tiktok) }
                )

                socialIconButton(
                    systemImage: "f.cursive.circle.fill",
                    action: { openURL(AppExternalLinks.facebook) }
                )

                socialIconButton(
                    systemImage: "message.fill",
                    action: { openURL(AppExternalLinks.whatsapp) }
                )

                socialIconButton(
                    systemImage: "map.fill",
                    action: { openURL(AppExternalLinks.maps) }
                )
            }
            .frame(maxWidth: .infinity)
            .appCardStyle(theme)
        }
    }

    private func socialIconButton(
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(palette.chipGradient)
                    .frame(width: 52, height: 52)

                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }
            .overlay(
                Circle()
                    .stroke(palette.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            Spacer()
        }
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
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
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
}
