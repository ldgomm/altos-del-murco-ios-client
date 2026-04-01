//
//  OrderRowView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct OrderRowView: View {
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
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.clientName.isEmpty ? "Walk-in customer" : order.clientName)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Label("Table \(order.tableNumber)", systemImage: "tablecells")
                        Label(order.createdAt.relativeTimeString, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                OrderStatusBadge(status: effectiveStatus)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(progressText)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(order.totalAmount.priceText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                ProgressView(value: progressValue)
            }

            if order.requiresReconfirmation {
                Label("Edited after confirmation", systemImage: "exclamationmark.arrow.trianglehead.2.clockwise")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if order.wasEditedAfterConfirmation {
                Label("Updated order", systemImage: "pencil.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                InfoChip(text: "Rev \(order.revision)", systemImage: "number")
                InfoChip(text: "\(order.items.count) lines", systemImage: "list.bullet")
                if let clientId = order.clientId, !clientId.isEmpty {
                    InfoChip(text: "Client linked", systemImage: "person.crop.circle.badge.checkmark")
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.primary.opacity(0.05))
        )
    }
}
