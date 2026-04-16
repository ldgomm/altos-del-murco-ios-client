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

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.cardGradient)

            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .overlay {
                    if let imageURL = item.imageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    palette.card
                                    ProgressView()
                                        .tint(palette.primary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                
                            case .failure:
                                ZStack {
                                    palette.card
                                    
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
                                
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                        )
                    }
                }

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(colorScheme == .dark ? 0.35 : 0.15),
                    .black.opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    BrandBadge(theme: .restaurant, title: "Featured", selected: true)
                    Spacer()
                }
                
                Text(item.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)

                Text(String(format: "$%.2f", item.finalPrice))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(18)
        }
        .frame(height: 200)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .stroke(palette.stroke.opacity(0.6), lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.22 : 0.12),
            radius: 16,
            x: 0,
            y: 10
        )
    }
}
