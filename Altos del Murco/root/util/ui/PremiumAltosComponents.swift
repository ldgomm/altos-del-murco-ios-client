import SwiftUI

struct PremiumAltosCopy {
    static let brand = "Altos del Murco"
    static let promise = "Restaurante y experiencias de montaña"
    static let restaurantCTA = "Pedir comida"
    static let experiencesCTA = "Reservar experiencia"
}

struct PremiumCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }
}

struct PremiumSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let systemImage {
                PremiumIconBubble(systemImage: systemImage)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.bold())
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct PremiumIconBubble: View {
    let systemImage: String
    var selected: Bool = false
    var size: CGFloat = 48

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
            .foregroundStyle(selected ? .white : .accentColor)
            .frame(width: size, height: size)
            .background(
                Circle().fill(selected ? Color.accentColor : Color.accentColor.opacity(0.14))
            )
    }
}

struct PremiumHero<Primary: View, Secondary: View>: View {
    let title: String
    let subtitle: String
    let badge: String
    let primary: Primary
    let secondary: Secondary

    init(
        title: String,
        subtitle: String,
        badge: String,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.primary = primary()
        self.secondary = secondary()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(badge)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.18), in: Capsule())
                Spacer()
                Text("ADM")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.18), in: Capsule())
            }

            Text(title)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.82)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.92))

            HStack(spacing: 12) {
                primary
                secondary
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.95), Color.orange.opacity(0.88), Color.black.opacity(0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 34, style: .continuous)
        )
        .shadow(color: .black.opacity(0.20), radius: 22, x: 0, y: 14)
    }
}

struct PremiumMetricTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PremiumIconBubble(systemImage: systemImage, size: 38)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct PremiumPriceRow: View {
    let title: String
    let value: String
    var negative = false
    var bold = false

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(bold ? .black : .semibold)
                .foregroundStyle(negative ? .green : .primary)
        }
        .font(bold ? .headline : .subheadline)
    }
}

struct PremiumRewardCard: View {
    let reward: RewardPresentation

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            PremiumIconBubble(systemImage: "checkmark.seal.fill", selected: true, size: 38)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reward.badge)
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                    if let amountText = reward.amountText {
                        Text("-\(amountText)")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                }
                Text(reward.title)
                    .font(.subheadline.bold())
                Text(reward.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
