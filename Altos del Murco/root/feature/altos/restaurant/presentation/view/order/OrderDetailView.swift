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
                    title: "Productos",
                    subtitle: "Todo lo incluido en este pedido"
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .textCase(nil)
            }

            if !order.appliedRewards.isEmpty {
                Section {
                    rewardsCard
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                } header: {
                    BrandSectionHeader(
                        theme: .restaurant,
                        title: "Premios aplicados",
                        subtitle: "Beneficios usados automáticamente en este pedido."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .textCase(nil)
                }
            }

            Section {
                amountsCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            } header: {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Montos"
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Detalle del pedido")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.restaurant)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.clientName.isEmpty ? "Cliente sin reserva" : order.clientName)
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text("Pedido #\(order.id.prefix(8))")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                OrderStatusBadge(status: effectiveStatus)
            }

            HStack(spacing: 12) {
                DetailMetricView(
                    title: "Mesa",
                    value: order.tableNumber,
                    systemImage: "tablecells"
                )

                DetailMetricView(
                    title: "Productos",
                    value: "\(order.totalItems)",
                    systemImage: "fork.knife"
                )
            }

            HStack(spacing: 12) {
                DetailMetricView(
                    title: "Creado",
                    value: order.createdAt.shortDateTimeString,
                    systemImage: "calendar"
                )

                DetailMetricView(
                    title: "Actualizado",
                    value: order.updatedAt.shortDateTimeString,
                    systemImage: "clock.arrow.circlepath"
                )
            }

            if order.isScheduledForLater {
                HStack(spacing: 12) {
                    DetailMetricView(
                        title: "Reserva",
                        value: order.scheduledDateText,
                        systemImage: "calendar.badge.clock"
                    )

                    DetailMetricView(
                        title: "WhatsApp",
                        value: order.contactDisplayText,
                        systemImage: "phone.fill"
                    )
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Progreso de preparación")
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
                Label("Este pedido necesita reconfirmación antes de que cocina continúe.", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(palette.warning)
                    .padding(.top, 2)
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(order.appliedRewards) { reward in
                HStack(alignment: .top, spacing: 12) {
                    BrandBadge(theme: .restaurant, title: "Premio", selected: true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reward.title)
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text(reward.note)
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()

                    Text("-\(reward.amount.priceText)")
                        .font(.subheadline.bold())
                        .foregroundStyle(palette.success)
                }
            }
        }
        .appCardStyle(.restaurant)
    }

    private var amountsCard: some View {
        VStack(spacing: 0) {
            detailLine(title: "Subtotal", value: order.subtotal.priceText)

            if order.loyaltyDiscountAmount > 0 {
                Divider().overlay(palette.stroke)
                detailLine(
                    title: "Murco Loyalty",
                    value: "-\(order.loyaltyDiscountAmount.priceText)"
                )
            }

            Divider().overlay(palette.stroke)
            detailLine(title: "Total", value: order.totalAmount.priceText, emphasized: true)
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
