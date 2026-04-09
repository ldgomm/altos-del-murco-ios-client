//
//  OrderStatusBadge.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrderStatusBadge: View {
    let status: OrderStatus
    var theme: AppSectionTheme = .restaurant
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            
            Text(status.title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(statusColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
        )
        .overlay(
            Capsule()
                .stroke(statusColor.opacity(colorScheme == .dark ? 0.35 : 0.20), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch status {
        case .pending:
            return palette.warning
        case .confirmed:
            return palette.secondary
        case .preparing:
            return Color.adaptive(
                light: UIColor(hex: 0x7C3AED),
                dark: UIColor(hex: 0xB794F4)
            )
        case .completed:
            return palette.success
        case .canceled:
            return palette.destructive
        }
    }
}

struct ItemStatusBadge: View {
    let isCompleted: Bool
    let isStarted: Bool
    var theme: AppSectionTheme = .restaurant
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text(title)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(colorScheme == .dark ? 0.18 : 0.12))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(colorScheme == .dark ? 0.30 : 0.18), lineWidth: 1)
        )
    }

    private var title: String {
        if isCompleted { return "Ready" }
        if isStarted { return "In progress" }
        return "Waiting"
    }

    private var color: Color {
        if isCompleted { return palette.success }
        if isStarted { return palette.warning }
        return palette.textSecondary
    }
}

struct InfoChip: View {
    let text: String
    let systemImage: String
    var theme: AppSectionTheme = .restaurant
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.medium))
            .foregroundStyle(palette.textSecondary)
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

struct DetailMetricView: View {
    let title: String
    let value: String
    let systemImage: String
    var theme: AppSectionTheme = .restaurant
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(palette.chipGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(palette.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.06),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}
