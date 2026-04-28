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
    
    private var stockTextColor: Color {
        item.canBeOrdered ? palette.textSecondary : palette.destructive
    }
    
    private var stockBackground: Color {
        item.canBeOrdered
        ? palette.elevatedCard
        : palette.destructive.opacity(colorScheme == .dark ? 0.22 : 0.12)
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
            color: palette.shadow.opacity(colorScheme == .dark ? 0.18 : 0.08),
            radius: 10,
            x: 0,
            y: 6
        )
        .opacity(item.canBeOrdered ? 1 : 0.58)
    }
    
    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(palette.elevatedCard)
            .frame(width: 88, height: 88)
            .overlay {
                if let imageURL = item.imageURL,
                   let url = URL(string: imageURL) {
                    RemoteImageView(
                        url: url,
                        contentMode: .fill,
                        targetPixelSize: CGSize(width: 88, height: 88)
                    ) {
                        ZStack {
                            palette.elevatedCard

                            ProgressView()
                                .tint(palette.primary)
                        }
                    }
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundStyle(palette.primary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(item.name)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
                .lineLimit(2)
            
            Spacer()
            
            if item.isFeatured {
                statusBadge(
                    title: "Popular",
                    textColor: palette.primary,
                    background: palette.primary.opacity(0.12)
                )
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
            
            statusBadge(
                title: item.stockLabel,
                textColor: stockTextColor,
                background: stockBackground
            )
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
