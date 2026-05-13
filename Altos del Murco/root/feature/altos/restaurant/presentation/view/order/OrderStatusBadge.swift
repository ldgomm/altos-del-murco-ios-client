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
    var useClientTitle: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)

            Text(useClientTitle ? status.clientTitle : status.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
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
        case .readyForPayment:
            return Color.adaptive(
                light: UIColor(hex: 0x2563EB),
                dark: UIColor(hex: 0x60A5FA)
            )
        case .paid:
            return palette.success
        case .canceled:
            return palette.destructive
        }
    }
}

struct ItemStatusBadge: View {
    let status: OrderItemStatus
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

            Text(status.clientTitle)
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

    private var color: Color {
        switch status {
        case .pending:
            return palette.textSecondary
        case .preparing:
            return palette.warning
        case .readyForDelivery:
            return palette.primary
        case .delivered:
            return palette.success
        case .canceled:
            return palette.destructive
        }
    }
}
