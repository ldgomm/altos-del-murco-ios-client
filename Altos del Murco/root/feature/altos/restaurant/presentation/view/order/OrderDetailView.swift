//
//  OrderDetailView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

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
                headerCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(order.items) { item in
                    OrderDetailItemRow(item: item)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                }
            } header: {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Items",
                    subtitle: "Everything included in this order"
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .textCase(nil)
            }

            Section {
                amountsCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            } header: {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Amounts"
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .textCase(nil)
            }

            Section {
                metadataCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 24, trailing: 16))
                    .listRowBackground(Color.clear)
            } header: {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Order metadata"
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Order Detail")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.restaurant)
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.clientName.isEmpty ? "Walk-in customer" : order.clientName)
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text("Order #\(order.id.prefix(8))")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
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

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Preparation progress")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    Text("\(order.preparedItemsCount)/\(order.totalItems)")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                ProgressView(value: progressValue)
                    .tint(palette.accent)
            }

            if order.requiresReconfirmation {
                Label("This order needs reconfirmation before kitchen proceeds.", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(palette.warning)
                    .padding(.top, 2)
            }
        }
        .appCardStyle(.restaurant, emphasized: true)
    }
    
    private var amountsCard: some View {
        VStack(spacing: 0) {
            detailLine(title: "Subtotal", value: order.subtotal.priceText)
            Divider().overlay(palette.stroke)
            detailLine(title: "Total", value: order.totalAmount.priceText, emphasized: true)
        }
        .appCardStyle(.restaurant)
    }
    
    private var metadataCard: some View {
        VStack(spacing: 0) {
            detailLine(title: "Revision", value: "\(order.revision)")
            Divider().overlay(palette.stroke)
            detailLine(title: "Last confirmed revision", value: order.lastConfirmedRevision.map(String.init) ?? "—")
            Divider().overlay(palette.stroke)
            detailLine(title: "Client ID", value: order.clientId ?? "—")
            Divider().overlay(palette.stroke)
            detailLine(title: "Lines", value: "\(order.items.count)")
        }
        .appCardStyle(.restaurant)
    }
    
    private func detailLine(title: String, value: String, emphasized: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)

            Spacer()

            Text(value)
                .font(emphasized ? .headline : .subheadline.weight(.semibold))
                .foregroundStyle(emphasized ? palette.primary : palette.textPrimary)
        }
        .padding(.vertical, 14)
    }
}
