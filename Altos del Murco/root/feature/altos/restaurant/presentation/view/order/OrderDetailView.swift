//
//  OrderDetailView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order

    private var effectiveStatus: OrderStatus {
        order.recalculatedStatus()
    }

    private var progressValue: Double {
        guard order.totalItems > 0 else { return 0 }
        return Double(order.preparedItemsCount) / Double(order.totalItems)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(order.clientName.isEmpty ? "Walk-in customer" : order.clientName)
                                .font(.title3)
                                .fontWeight(.bold)

                            Text("Order #\(order.id.prefix(8))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        OrderStatusBadge(status: effectiveStatus)
                    }

                    HStack(spacing: 12) {
                        DetailMetricView(
                            title: "Table",
                            value: order.tableNumber,
                            systemImage: "tablecells"
                        )
                        DetailMetricView(
                            title: "Items",
                            value: "\(order.totalItems)",
                            systemImage: "fork.knife"
                        )
                    }

                    HStack(spacing: 12) {
                        DetailMetricView(
                            title: "Created",
                            value: order.createdAt.shortDateTimeString,
                            systemImage: "calendar"
                        )
                        DetailMetricView(
                            title: "Updated",
                            value: order.updatedAt.shortDateTimeString,
                            systemImage: "clock.arrow.circlepath"
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Preparation progress")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Text("\(order.preparedItemsCount)/\(order.totalItems)")
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: progressValue)
                    }

                    if order.requiresReconfirmation {
                        Label("This order needs reconfirmation before kitchen proceeds.", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Items") {
                ForEach(order.items) { item in
                    OrderDetailItemRow(item: item)
                }
            }

            Section("Amounts") {
                LabeledContent("Subtotal", value: order.subtotal.priceText)
                LabeledContent("Total", value: order.totalAmount.priceText)
            }

            Section("Order metadata") {
                LabeledContent("Revision", value: "\(order.revision)")
                LabeledContent("Last confirmed revision", value: order.lastConfirmedRevision.map(String.init) ?? "—")
                LabeledContent("Client ID", value: order.clientId ?? "—")
                LabeledContent("Lines", value: "\(order.items.count)")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Order Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
