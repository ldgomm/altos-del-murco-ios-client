//
//  OrderDetailItemRow.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrderDetailItemRow: View {
    let item: OrderItem

    private var statusText: String {
        if item.isCompleted { return "Ready" }
        if item.isStarted { return "In progress" }
        return "Waiting"
    }

    private var progressValue: Double {
        guard item.quantity > 0 else { return 0 }
        return Double(item.preparedQuantity) / Double(item.quantity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)

                    Text("\(item.quantity) × \(item.unitPrice.priceText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(item.totalPrice.priceText)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ItemStatusBadge(isCompleted: item.isCompleted, isStarted: item.isStarted)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Prepared: \(item.preparedQuantity)/\(item.quantity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(item.isCompleted ? .green : item.isStarted ? .orange : .secondary)
                }

                ProgressView(value: progressValue)
            }

            if let notes = item.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .foregroundStyle(.secondary)

                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.vertical, 6)
    }
}
