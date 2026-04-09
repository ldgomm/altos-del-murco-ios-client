//
//  MenuItemRowView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct MenuItemRowView: View {
    let item: MenuItem
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            thumbnail
            
            VStack(alignment: .leading, spacing: 8) {
                headerSection
                descriptionSection
                footerSection
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.20 : 0.08),
            radius: 12,
            x: 0,
            y: 6
        )
    }
    
    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.chipGradient)
                .frame(width: 74, height: 74)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.stroke, lineWidth: 1)
                )
            
            Image(systemName: "fork.knife")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(palette.primary)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(item.isAvailable ? palette.textPrimary : palette.textSecondary)
            
            HStack(spacing: 8) {
                if item.isFeatured {
                    statusBadge(
                        title: "Popular",
                        textColor: palette.warning,
                        background: palette.warning.opacity(colorScheme == .dark ? 0.20 : 0.12)
                    )
                }
                
                if item.hasOffer {
                    statusBadge(
                        title: "Offer",
                        textColor: palette.success,
                        background: palette.success.opacity(colorScheme == .dark ? 0.20 : 0.12)
                    )
                }
                
                if !item.isAvailable {
                    statusBadge(
                        title: "Sold out",
                        textColor: palette.destructive,
                        background: palette.destructive.opacity(colorScheme == .dark ? 0.20 : 0.12)
                    )
                }
            }
        }
    }
    
    private var descriptionSection: some View {
        Text(item.description)
            .font(.subheadline)
            .foregroundStyle(palette.textSecondary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
    }
    
    private var footerSection: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            if item.hasOffer, let offerPrice = item.offerPrice {
                Text(item.price.priceText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textTertiary)
                    .strikethrough()
                
                Text(offerPrice.priceText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(palette.accent)
            } else {
                Text(item.price.priceText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(palette.primary)
            }
            
            Spacer()
        }
        .padding(.top, 2)
    }
    
    private func statusBadge(
        title: String,
        textColor: Color,
        background: Color
    ) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(background)
            )
            .overlay(
                Capsule()
                    .stroke(textColor.opacity(0.18), lineWidth: 1)
            )
    }
}
