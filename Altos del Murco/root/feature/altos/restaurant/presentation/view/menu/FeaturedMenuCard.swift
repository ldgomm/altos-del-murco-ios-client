//
//  FeaturedMenuCard.swift
//  Altos del Murco
//
//  Created by José Ruiz on 15/4/26.
//

import SwiftUI

struct FeaturedMenuCard: View {
    let item: MenuItem

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: AppTheme.Radius.xLarge,
            style: .continuous
        )
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            cardBackground
            imageLayer
            seasonalLayer
            gradientOverlay
            content
        }
        .frame(height: 200)
        .clipShape(cardShape)
        .overlay {
            cardShape
                .stroke(palette.stroke.opacity(0.6), lineWidth: 1)
        }
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.22 : 0.12),
            radius: 16,
            x: 0,
            y: 10
        )
    }

    private var cardBackground: some View {
        cardShape.fill(palette.cardGradient)
    }

    private var seasonalLayer: some View {
        SeasonalAnimatedCardBackdrop(
            seasonalTheme: EcuadorSeasonalCalendar.activeTheme(),
            cornerRadius: AppTheme.Radius.xLarge,
            intensity: 0.95
        )
        .blendMode(colorScheme == .dark ? .screen : .plusLighter)
    }

    @ViewBuilder
    private var imageLayer: some View {
        if let imageURL = item.imageURL,
           let url = URL(string: imageURL) {
            GeometryReader { proxy in
                RemoteImageView(
                    url: url,
                    contentMode: .fill,
                    targetPixelSize: CGSize(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                ) {
                    ZStack {
                        palette.card

                        ProgressView()
                            .tint(palette.primary)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            palette.cardGradient

            VStack(spacing: 10) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(palette.primary)

                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [
                .clear,
                .black.opacity(colorScheme == .dark ? 0.35 : 0.15),
                .black.opacity(0.72)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                BrandBadge(theme: .restaurant, title: "Destacados", selected: true)
                Spacer()

                if let seasonal = EcuadorSeasonalCalendar.activeTheme() {
                    SeasonalTinyBadge(theme: seasonal, palette: palette)
                }
            }

            Text(item.name)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(item.description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(2)

            HStack(spacing: 8) {
                if item.hasOffer {
                    Text(item.price.priceText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .strikethrough()
                }

                Text(item.finalPrice.priceText)
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
        .padding(18)
    }
}
