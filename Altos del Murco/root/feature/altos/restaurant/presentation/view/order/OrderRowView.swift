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
        "\(order.preparedItemsCount)/\(order.totalItems) items"
    }

    private var progressValue: Double {
        guard order.totalItems > 0 else { return 0 }
        return Double(order.preparedItemsCount) / Double(order.totalItems)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.clientName.isEmpty ? "Walk-in customer" : order.clientName)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    HStack(spacing: 8) {
                        Label("Table \(order.tableNumber)", systemImage: "tablecells")
                        Label(order.createdAt.relativeTimeString, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
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

                    Text(order.totalAmount.priceText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(palette.primary)
                }

                ProgressView(value: progressValue)
                    .tint(progressColor)
            }

            if order.requiresReconfirmation {
                Label("Edited after confirmation", systemImage: "exclamationmark.arrow.trianglehead.2.clockwise")
                    .font(.caption)
                    .foregroundStyle(palette.warning)
            } else if order.wasEditedAfterConfirmation {
                Label("Updated order", systemImage: "pencil.circle")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
    }
}
