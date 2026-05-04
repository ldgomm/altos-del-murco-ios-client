//
//  CheckoutView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct CheckoutView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Binding var path: NavigationPath
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var authenticatedProfile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }

    private var effectiveTotal: Double {
        viewModel.effectiveTotal(for: cartManager.subtotal)
    }

    private var rowDiscounts: [UUID: Double] {
        viewModel.allocatedDiscountByCartItemId(for: cartManager.items)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                clientDetailsSection
                scheduleSection
                summarySection
                rewardsSection
                confirmSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .navigationTitle("Confirmación")
        .appScreenStyle(.restaurant)
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.state.errorMessage != nil },
                set: { isPresented in
                    if !isPresented { viewModel.clearError() }
                }
            ),
            actions: {
                Button("Aceptar") { viewModel.clearError() }
            },
            message: { Text(viewModel.state.errorMessage ?? "") }
        )
        .onAppear {
            syncProfileFieldsFromSession()
            cartManager.refreshDefaultScheduleIfNeeded()
            let nationalId = authenticatedProfile?.id ?? cartManager.clientId ?? ""
            viewModel.onAppear(nationalId: nationalId)
        }
        .onChange(of: authenticatedProfile?.id) { _, _ in
            syncProfileFieldsFromSession()
            let nationalId = authenticatedProfile?.id ?? cartManager.clientId ?? ""
            viewModel.onAppear(nationalId: nationalId)
        }
        .onChange(of: authenticatedProfile?.fullName) { _, _ in
            syncProfileFieldsFromSession()
        }
        .onChange(of: viewModel.state.createdOrder) { _, order in
            guard let order else { return }
            path.append(Route.orderSuccess(order))
        }
    }

    private var clientDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Datos para confirmar",
                subtitle: "Estos datos solo se solicitan cuando vas a crear un pedido o reserva real."
            )

            VStack(spacing: 14) {
                themedField(
                    title: "Cédula / número único nacional",
                    text: Binding(
                        get: { cartManager.nationalId ?? "" },
                        set: { cartManager.updateClientId($0) }
                    )
                )
                .keyboardType(.numberPad)

                themedField(
                    title: "Nombre",
                    text: Binding(
                        get: { cartManager.clientName },
                        set: { cartManager.updateClientName($0) }
                    )
                )
                .textInputAutocapitalization(.words)

                themedField(
                    title: cartManager.isScheduledForLater ? "Mesa o referencia" : "Número de mesa",
                    text: Binding(
                        get: { cartManager.tableNumber },
                        set: { cartManager.updateTableNumber($0) }
                    )
                )
                .keyboardType(.default)

                Text(cartManager.isScheduledForLater
                     ? "Para una reserva posterior puedes dejar la mesa vacía; ADM la verá como Por asignar."
                     : "Para pedidos inmediatos, indica la mesa donde debe llegar la comida.")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)

                Text("La cédula es obligatoria solo para confirmar el pedido o servicio. No se requiere para ver el menú.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.restaurant)
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Cuándo preparar",
                subtitle: "Reserva solo comida para más tarde sin entrar al módulo de aventura."
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: cartManager.isScheduledForLater ? "calendar.badge.clock" : "bolt.fill")
                        .font(.title3)
                        .foregroundStyle(palette.primary)
                        .frame(width: 34)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(cartManager.isScheduledForLater ? "Reserva de comida" : "Pedido inmediato")
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text(OrderScheduleResolver.displayText(for: cartManager.scheduledAt))
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()

                    Button("Ahora") {
                        viewModel.onEvent(.scheduleNowTapped)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!cartManager.isScheduledForLater)
                }

                DatePicker(
                    "Fecha y hora",
                    selection: Binding(
                        get: { cartManager.scheduledAt },
                        set: { viewModel.onEvent(.scheduledAtChanged($0)) }
                    ),
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)

                Text("Por defecto es ahora. Si eliges otro día, se guardará como reserva de comida en restaurant_orders con scheduledAt.")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.restaurant)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Resumen",
                subtitle: "Revisa tu pedido antes de confirmarlo."
            )

            VStack(spacing: 12) {
                ForEach(cartManager.items) { cartItem in
                    let lineDiscount = rowDiscounts[cartItem.id, default: 0]
                    let discountedLine = max(0, cartItem.totalPrice - lineDiscount)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(cartItem.quantity)x \(cartItem.menuItem.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(palette.textPrimary)

                            if let reward = viewModel.appliedRewardPresentation(forMenuItemId: cartItem.menuItem.id) {
                                Text(reward.message)
                                    .font(.caption)
                                    .foregroundStyle(palette.success)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            if lineDiscount > 0 {
                                Text(cartItem.totalPrice.priceText)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                                    .strikethrough()

                                Text(discountedLine.priceText)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(palette.success)
                            } else {
                                Text(cartItem.totalPrice.priceText)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(palette.textPrimary)
                            }
                        }
                    }

                    if cartItem.id != cartManager.items.last?.id {
                        Divider().overlay(palette.stroke)
                    }
                }
            }

            Divider().overlay(palette.stroke)
            detailLine(title: "Subtotal", value: cartManager.subtotal.priceText)

            if viewModel.state.isLoadingRewards {
                detailLine(title: "Murco Loyalty", value: "Calculando...", secondary: true)
            } else if viewModel.state.rewardPreview.discountAmount > 0 {
                detailLine(title: "Murco Loyalty", value: "-\(viewModel.state.rewardPreview.discountAmount.priceText)", accent: true)
            }

            detailLine(title: cartManager.isScheduledForLater ? "Reserva" : "Hora", value: OrderScheduleResolver.displayText(for: cartManager.scheduledAt), secondary: true)

            Divider().overlay(palette.stroke)
            detailLine(title: "Total", value: effectiveTotal.priceText, emphasized: true)
        }
        .appCardStyle(.restaurant)
    }

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Premios aplicados",
                subtitle: viewModel.state.rewardPreview.appliedRewards.isEmpty
                    ? "No hay premios activos para este pedido."
                    : "Estos descuentos ya se reflejan en el total."
            )

            if viewModel.state.isLoadingRewards {
                ProgressView("Calculando premios...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if viewModel.state.rewardPreview.appliedRewards.isEmpty {
                Text("No se aplicó ningún cupón o premio automático a este pedido.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.state.rewardPreview.appliedRewards) { reward in
                        HStack(alignment: .top, spacing: 10) {
                            BrandBadge(theme: .restaurant, title: "Aplicado", selected: true)

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
        }
        .appCardStyle(.restaurant)
    }

    private var confirmSection: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cartManager.isScheduledForLater ? "Total de la reserva" : "Total a pagar")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    Text(effectiveTotal.priceText)
                        .font(.title2.bold())
                        .foregroundStyle(palette.textPrimary)
                }

                Spacer()
            }

            Button {
                viewModel.onEvent(.confirmTapped)
            } label: {
                if viewModel.state.isSubmitting {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text(cartManager.isScheduledForLater ? "Confirmar reserva de comida" : "Confirmar pedido")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
            .disabled(!cartManager.canSubmit || viewModel.state.isSubmitting)
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private func syncProfileFieldsFromSession() {
        guard let profile = authenticatedProfile else { return }

        let profileNationalId = profile.nationalId.digitsOnly
        if (cartManager.nationalId ?? "").isEmpty && !profileNationalId.isEmpty {
            cartManager.nationalId = profileNationalId
        }

        if cartManager.clientName.trimmed.isEmpty && !profile.fullName.trimmed.isEmpty {
            cartManager.clientName = profile.fullName
        }
    }

    private func themedField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textSecondary)

            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func detailLine(
        title: String,
        value: String,
        emphasized: Bool = false,
        secondary: Bool = false,
        accent: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(emphasized ? .headline : .subheadline)
                .foregroundStyle(accent ? palette.success : (secondary ? palette.textSecondary : palette.textPrimary))

            Spacer()

            Text(value)
                .font(emphasized ? .headline.bold() : .subheadline.weight(.semibold))
                .foregroundStyle(accent ? palette.success : (secondary ? palette.textSecondary : palette.textPrimary))
        }
    }
}
