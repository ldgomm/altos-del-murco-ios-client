//
//  OrderRowView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct OrderRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var progressColor: Color {
        switch effectiveStatus {
        case .pending:
            return palette.warning
        case .confirmed:
            return palette.secondary
        case .preparing:
            return palette.accent
        case .completed:
            return palette.success
        case .canceled:
            return palette.destructive
        }
    }

    let order: Order

    private var effectiveStatus: OrderStatus {
        order.recalculatedStatus()
    }

    private var progressText: String {
        "\(order.preparedItemsCount)/\(order.totalItems) productos"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.clientName.isEmpty ? "Cliente sin reserva" : order.clientName)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    HStack(spacing: 8) {
                        Label("Mesa \(order.tableNumber)", systemImage: "tablecells")
                        Label(order.isScheduledForLater ? order.scheduledDateText : order.createdAt.relativeTimeString, systemImage: order.isScheduledForLater ? "calendar.badge.clock" : "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)

                    if order.isScheduledForLater {
                        Label(order.contactDisplayText, systemImage: "phone.fill")
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                OrderStatusBadge(status: effectiveStatus)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(progressText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if order.loyaltyDiscountAmount > 0 {
                            Text(order.subtotal.priceText)
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                                .strikethrough()

                            Text(order.totalAmount.priceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(palette.success)
                        } else {
                            Text(order.totalAmount.priceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(palette.primary)
                        }
                    }
                }

                ProgressView(value: progressValue)
                    .tint(progressColor)
            }

            if order.loyaltyDiscountAmount > 0 || !order.appliedRewards.isEmpty {
                Divider().overlay(palette.stroke)

                HStack(alignment: .top, spacing: 8) {
                    BrandBadge(theme: .restaurant, title: "Murco", selected: true)

                    VStack(alignment: .leading, spacing: 4) {
                        if order.loyaltyDiscountAmount > 0 {
                            Text("Descuento aplicado: -\(order.loyaltyDiscountAmount.priceText)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.success)
                        }

                        if let reward = order.appliedRewards.first {
                            Text(reward.note)
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()
                }
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private var progressValue: Double {
        guard order.totalItems > 0 else { return 0 }
        return Double(order.preparedItemsCount) / Double(order.totalItems)
    }
}
