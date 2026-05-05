//
//  OrderSuccessView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct OrderSuccessView: View {
    let order: Order

    @Binding var path: NavigationPath
    @Environment(\.colorScheme) private var colorScheme

    private let theme: AppSectionTheme = .restaurant

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                successHeader
                orderDetailsCard
                rewardsCard

                Button {
                    path = NavigationPath()
                } label: {
                    Text("Listo")
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: theme))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Éxito")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .appScreenStyle(theme)
    }

    private var successHeader: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(palette.chipGradient)
                    .frame(width: 108, height: 108)
                    .overlay(
                        Circle()
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                    .shadow(
                        color: palette.shadow.opacity(colorScheme == .dark ? 0.24 : 0.10),
                        radius: 18,
                        x: 0,
                        y: 10
                    )

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(palette.success)
            }

            VStack(spacing: 8) {
                Text(order.isScheduledForLater ? "Reserva enviada" : "Pedido enviado")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                Text(order.isScheduledForLater ? "Tu reserva de comida fue creada correctamente." : "Tu pedido fue creado correctamente.")
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    private var orderDetailsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            BrandSectionHeader(
                theme: theme,
                title: "Resumen del pedido",
                subtitle: "Tu pedido del restaurante ha sido registrado correctamente."
            )

            VStack(spacing: 14) {
                InfoRow(title: "ID del pedido", value: String(order.id.prefix(7)), theme: theme)
                InfoRow(title: "Cliente", value: order.clientName, theme: theme)
                InfoRow(title: "Mesa", value: order.tableNumber, theme: theme)
                if order.isScheduledForLater {
                    InfoRow(title: "Reserva", value: order.scheduledDateText, theme: theme)
                    InfoRow(title: "WhatsApp", value: order.contactDisplayText, theme: theme)
                }
                InfoRow(title: "Estado", value: order.status.title, theme: theme)
                InfoRow(
                    title: order.isScheduledForLater ? "Creada" : "Hora",
                    value: order.createdAt.formatted(date: .omitted, time: .shortened),
                    theme: theme
                )
                InfoRow(title: "Subtotal", value: order.subtotal.priceText, theme: theme)
                if order.loyaltyDiscountAmount > 0 {
                    InfoRow(
                        title: "Murco Loyalty",
                        value: "-\(order.loyaltyDiscountAmount.priceText)",
                        theme: theme
                    )
                }
                InfoRow(title: "Total", value: order.totalAmount.priceText, theme: theme, emphasized: true)
            }
        }
        .appCardStyle(theme, emphasized: false)
    }

    @ViewBuilder
    private var rewardsCard: some View {
        if !order.appliedRewards.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: theme,
                    title: "Premios aplicados",
                    subtitle: "Estos premios quedaron guardados con tu pedido."
                )

                VStack(spacing: 12) {
                    ForEach(order.appliedRewards) { reward in
                        HStack(alignment: .top, spacing: 10) {
                            BrandBadge(theme: theme, title: "Aplicado", selected: true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(reward.title)
                                    .font(.subheadline.bold())
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
            }
            .appCardStyle(theme)
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    let theme: AppSectionTheme
    var emphasized: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
            
            Spacer(minLength: 16)
            
            Text(value)
                .font(emphasized ? .headline : .subheadline.weight(.semibold))
                .foregroundStyle(emphasized ? palette.primary : palette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}
