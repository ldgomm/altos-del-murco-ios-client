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

    private var activeItems: [OrderItem] {
        order.items.filter { $0.status != .canceled }
    }

    private var deliveredItems: [OrderItem] {
        activeItems.filter { $0.status == .delivered }
    }

    private var progressValue: Double {
        guard !activeItems.isEmpty else { return 0 }
        return Double(deliveredItems.count) / Double(activeItems.count)
    }

    private var progressText: String {
        guard !activeItems.isEmpty else { return "Sin productos activos" }
        return "\(deliveredItems.count)/\(activeItems.count) servidos"
    }

    var body: some View {
        List {
            Section {
                headerCard
                    .listRowInsets(
                        EdgeInsets(
                            top: 8,
                            leading: 16,
                            bottom: 8,
                            trailing: 16
                        )
                    )
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(order.items) { item in
                    OrderDetailItemRow(item: item)
                        .listRowInsets(
                            EdgeInsets(
                                top: 6,
                                leading: 16,
                                bottom: 6,
                                trailing: 16
                            )
                        )
                        .listRowBackground(Color.clear)
                }
            } header: {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Productos",
                    subtitle: "Cada línea representa una unidad exacta del pedido."
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .textCase(nil)
            }

            if !order.appliedRewards.isEmpty {
                Section {
                    rewardsCard
                        .listRowInsets(
                            EdgeInsets(
                                top: 8,
                                leading: 16,
                                bottom: 8,
                                trailing: 16
                            )
                        )
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
                    .listRowInsets(
                        EdgeInsets(
                            top: 8,
                            leading: 16,
                            bottom: 8,
                            trailing: 16
                        )
                    )
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
                    Text(order.clientName.isEmpty ? "Cliente" : order.clientName)
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
                    value: "\(order.items.count)",
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

            if effectiveStatus == .readyForPayment {
                statusNoticeCard(
                    title: "Pedido servido",
                    message: readyForPaymentMessage,
                    systemImage: "checkmark.seal.fill",
                    tint: palette.success
                )
            } else if effectiveStatus == .paid {
                statusNoticeCard(
                    title: "Pedido pagado",
                    message: paidMessage,
                    systemImage: "creditcard.fill",
                    tint: palette.success
                )
            } else if effectiveStatus == .canceled {
                statusNoticeCard(
                    title: "Pedido cancelado",
                    message: "Este pedido fue cancelado.",
                    systemImage: "xmark.octagon.fill",
                    tint: palette.destructive
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Progreso de entrega")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    Text(progressText)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                ProgressView(value: progressValue)
                    .tint(progressTint)
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private var readyForPaymentMessage: String {
        if !order.canceledItems.isEmpty && order.hasDeliveredItems {
            return "Se anuló lo no servido. Los platos servidos quedan listos para pagar."
        }

        return "Tu pedido ya fue servido y está listo para pagar."
    }

    private var paidMessage: String {
        if let paidAt = order.paidAt {
            return "Pago registrado el \(paidAt.shortDateTimeString)."
        }

        return "Pago registrado correctamente."
    }

    private var progressTint: Color {
        switch effectiveStatus {
        case .pending:
            return palette.warning
        case .confirmed:
            return palette.secondary
        case .preparing:
            return palette.accent
        case .readyForPayment, .paid:
            return palette.success
        case .canceled:
            return palette.destructive
        }
    }

    private func statusNoticeCard(
        title: String,
        message: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(tint.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(colorScheme == .dark ? 0.16 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(colorScheme == .dark ? 0.28 : 0.18), lineWidth: 1)
        )
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

            if effectiveStatus == .paid {
                Divider().overlay(palette.stroke)
                detailLine(
                    title: "Estado de pago",
                    value: "Pagado",
                    emphasized: true
                )
            }
        }
        .appCardStyle(.restaurant)
    }

    private func detailLine(
        title: String,
        value: String,
        emphasized: Bool = false
    ) -> some View {
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

struct DetailMetricView: View {
    let title: String
    let value: String
    let systemImage: String
    var theme: AppSectionTheme = .restaurant
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(palette.chipGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(palette.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.06),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}
