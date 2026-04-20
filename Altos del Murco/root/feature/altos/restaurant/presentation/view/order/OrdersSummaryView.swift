//
//  OrdersSummaryView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrdersSummaryView: View {
    let orders: [Order]
    var theme: AppSectionTheme = .restaurant

    private var pendingCount: Int {
        orders.filter { $0.recalculatedStatus() == .pending }.count
    }

    private var preparingCount: Int {
        orders.filter { $0.recalculatedStatus() == .preparing }.count
    }

    private var completedCount: Int {
        orders.filter { $0.recalculatedStatus() == .completed }.count
    }

    private var totalRevenue: Double {
        orders
            .filter { $0.recalculatedStatus() != .canceled }
            .reduce(0) { $0 + $1.totalAmount }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            SummaryMetricCard(
                theme: theme,
                title: "Pendientes",
                value: "\(pendingCount)",
                systemImage: "clock",
                tone: .warning
            )

            SummaryMetricCard(
                theme: theme,
                title: "En preparación",
                value: "\(preparingCount)",
                systemImage: "flame.fill",
                tone: .accent
            )

            SummaryMetricCard(
                theme: theme,
                title: "Completados",
                value: "\(completedCount)",
                systemImage: "checkmark.circle.fill",
                tone: .success
            )

            SummaryMetricCard(
                theme: theme,
                title: "Ingresos",
                value: totalRevenue.priceText,
                systemImage: "dollarsign.circle.fill",
                tone: .primary,
                emphasized: true
            )
        }
    }
}

enum SummaryMetricTone {
    case primary
    case accent
    case success
    case warning
}

struct SummaryMetricCard: View {
    let theme: AppSectionTheme
    let title: String
    let value: String
    let systemImage: String
    let tone: SummaryMetricTone
    var emphasized: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    private var valueColor: Color {
        switch tone {
        case .primary:
            return palette.primary
        case .accent:
            return palette.accent
        case .success:
            return palette.success
        case .warning:
            return palette.warning
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textSecondary)

                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .appCardStyle(theme, emphasized: emphasized)
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(palette.chipGradient)
                .frame(width: 46, height: 46)

            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .overlay(
            Circle()
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
}
