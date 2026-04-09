//
//  ServiceCardView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ServiceCardView: View {
    let service: AdventureService
    var theme: AppSectionTheme = .adventure
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        HStack(alignment: .top, spacing: 14) {
            BrandIconBubble(
                theme: theme,
                systemImage: service.systemImage,
                size: 60
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(service.title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                
                Text(service.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    metadataChip(
                        title: service.priceText,
                        systemImage: "dollarsign.circle"
                    )
                    
                    metadataChip(
                        title: service.durationText,
                        systemImage: "clock"
                    )
                }
                .padding(.top, 2)
            }
            
            Spacer(minLength: 8)
            
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
                .padding(.top, 4)
        }
//        .appCardStyle(theme, emphasized: false)
    }
    
    private func metadataChip(title: String, systemImage: String) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        return HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(palette.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(palette.chipGradient)
        )
        .overlay(
            Capsule()
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
}
