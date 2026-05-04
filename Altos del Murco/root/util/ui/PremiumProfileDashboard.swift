import SwiftUI

struct PremiumProfileDashboard: View {
    let profile: ClientProfile
    let stats: ProfileStats
    var isLoading: Bool = false
    let onEditProfile: () -> Void
    let onOpenAccount: () -> Void
    let onOpenPreferences: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 20) {
                PremiumSectionHeader(
                    title: "Perfil",
                    subtitle: "Tu identidad, nivel, beneficios y resumen de visitas.",
                    systemImage: "person.crop.circle"
                )

                identityCard
                loyaltyCard
                statsGrid
                rewardsSection
                accountSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .appScreenStyle(.neutral)
    }

    private var identityCard: some View {
        PremiumCard {
            HStack(alignment: .center, spacing: 14) {
                AsyncImage(url: profile.profileImageURL.flatMap(URL.init(string:))) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .frame(width: 78, height: 78)
                .clipShape(Circle())
                .background(Circle().fill(Color.accentColor.opacity(0.14)))

                VStack(alignment: .leading, spacing: 5) {
                    Text(profile.fullName.isEmpty ? "Cliente Altos" : profile.fullName)
                        .font(.title3.bold())
                        .lineLimit(2)
                    Text("Nivel \(stats.level.title)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }

                Spacer()

                Button(action: onEditProfile) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label(profile.phoneNumber.isEmpty ? "Sin teléfono registrado" : profile.phoneNumber, systemImage: "phone.fill")
                Label(profile.email.isEmpty ? "Sin email registrado" : profile.email, systemImage: "envelope.fill")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var loyaltyCard: some View {
        PremiumCard {
            HStack(spacing: 12) {
                PremiumIconBubble(systemImage: "crown.fill", selected: true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Murco Loyalty")
                        .font(.headline)
                    Text("Nivel \(stats.level.title) • \(stats.points) puntos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(stats.totalSpent.priceText)
                    .font(.headline.bold())
                    .foregroundStyle(.green)
            }

            ProgressView(value: LoyaltyLevel.progress(for: stats.totalSpent))
                .tint(.green)

            if let next = stats.level.nextLevel {
                Text("Siguiente meta: \(next.title) (\(next.spendRangeText))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Ya estás en el nivel máximo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

//            VStack(alignment: .leading, spacing: 8) {
//                ForEach(stats.level.benefits, id: \.self) { benefit in
//                    Label(benefit, systemImage: "star.fill")
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//            }
        }
    }

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                PremiumMetricTile(title: "Pedidos", value: "\(stats.completedOrders)", systemImage: "receipt.fill")
                PremiumMetricTile(title: "Reservas", value: "\(stats.completedBookings)", systemImage: "calendar")
            }
            HStack(spacing: 12) {
                PremiumMetricTile(title: "Restaurante", value: stats.restaurantSpent.priceText, systemImage: "fork.knife")
                PremiumMetricTile(title: "Experiencias", value: stats.adventureSpent.priceText, systemImage: "mountain.2.fill")
            }
        }
    }

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PremiumSectionHeader(
                title: "Beneficios activos",
                subtitle: "Todo descuento debe mostrarse antes del checkout.",
                systemImage: "gift.fill"
            )

            let rewards = stats.wallet.availableTemplates.filter { !$0.isExpired }.prefix(5)
            if rewards.isEmpty {
                PremiumCard {
                    Text("No tienes premios activos en este momento.")
                        .font(.headline)
                    Text("Sigue acumulando consumo para desbloquear nuevos beneficios.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(Array(rewards), id: \.id) { template in
                    PremiumCard {
                        Text(template.title)
                            .font(.headline)
                        Text(template.subtitle.isEmpty ? template.displaySummary : template.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Disponible para \(template.scope.title)")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PremiumSectionHeader(
                title: "Cuenta",
                subtitle: "Acciones secundarias separadas del tablero principal.",
                systemImage: "gearshape.fill"
            )

            HStack(spacing: 12) {
                Button(action: onOpenPreferences) {
                    Label("Preferencias", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onOpenAccount) {
                    Label("Cuenta", systemImage: "person.crop.circle.badge.gearshape")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
