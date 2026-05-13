//
//  OrderRowView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct OrderRowView: View {
    let order: Order

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var effectiveStatus: OrderStatus {
        order.recalculatedStatus()
    }

    private var activeItemsCount: Int {
        max(1, order.activeItems.count)
    }

    private var deliveredItemsCount: Int {
        order.deliveredItems.count
    }

    private var progressValue: Double {
        guard !order.activeItems.isEmpty else { return 0 }
        return Double(deliveredItemsCount) / Double(activeItemsCount)
    }

    private var progressText: String {
        switch effectiveStatus {
        case .pending:
            return "Pedido enviado"
        case .confirmed:
            return "Confirmado, esperando cocina"
        case .preparing:
            let readyCount = order.readyForDeliveryItems.count
            if readyCount > 0 {
                return "\(readyCount) listo(s) • \(deliveredItemsCount)/\(activeItemsCount) servidos"
            }
            return "\(deliveredItemsCount)/\(activeItemsCount) servidos"
        case .readyForPayment:
            return "Pedido servido, listo para pagar"
        case .paid:
            return "Pagado"
        case .canceled:
            return "Cancelado"
        }
    }

    private var progressColor: Color {
        switch effectiveStatus {
        case .pending:
            return palette.warning
        case .confirmed:
            return palette.secondary
        case .preparing:
            return palette.accent
        case .readyForPayment:
            return palette.primary
        case .paid:
            return palette.success
        case .canceled:
            return palette.destructive
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.clientName.isEmpty ? "Cliente sin reserva" : order.clientName)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    HStack(spacing: 8) {
                        Label("Mesa \(order.tableNumber.isEmpty ? "—" : order.tableNumber)", systemImage: "tablecells")
                        Label(
                            order.isScheduledForLater ? order.scheduledDateText : order.createdAt.relativeTimeString,
                            systemImage: order.isScheduledForLater ? "calendar.badge.clock" : "clock"
                        )
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

            if !order.readyForDeliveryItems.isEmpty {
                readyItemsBanner
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

    private var readyItemsBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Listo para servir", systemImage: "bell.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(palette.primary)

            ForEach(order.readyForDeliveryItems.prefix(3)) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text(item.displayQuantityText)
                        .font(.caption.weight(.black))
                        .foregroundStyle(palette.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)

                        if let notes = item.notes {
                            Text(notes)
                                .font(.caption2)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.primary.opacity(colorScheme == .dark ? 0.16 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.primary.opacity(0.24), lineWidth: 1)
        )
    }
}
