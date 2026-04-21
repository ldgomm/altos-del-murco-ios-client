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
                    if !isPresented {
                        viewModel.clearError()
                    }
                }
            ),
            actions: {
                Button("Aceptar") {
                    viewModel.clearError()
                }
            },
            message: {
                Text(viewModel.state.errorMessage ?? "")
            }
        )
        .onAppear {
            syncProfileFieldsFromSession()
            let nationalId = authenticatedProfile?.nationalId ?? cartManager.clientId ?? ""
            viewModel.onAppear(nationalId: nationalId)
        }
        .onChange(of: authenticatedProfile?.nationalId) { _, _ in
            syncProfileFieldsFromSession()
            let nationalId = authenticatedProfile?.nationalId ?? cartManager.clientId ?? ""
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
                title: "Datos del cliente",
                subtitle: "La información de tu perfil se utiliza automáticamente para este pedido."
            )

            VStack(spacing: 14) {
                themedField(
                    title: "Cédula",
                    text: Binding(
                        get: { authenticatedProfile?.nationalId ?? cartManager.clientId ?? "" },
                        set: { _ in }
                    )
                )
                .disabled(true)

                themedField(
                    title: "Nombre",
                    text: Binding(
                        get: { authenticatedProfile?.fullName ?? cartManager.clientName },
                        set: { _ in }
                    )
                )
                .disabled(true)

                themedField(
                    title: "Número de mesa",
                    text: Binding(
                        get: { cartManager.tableNumber },
                        set: { cartManager.updateTableNumber($0) }
                    )
                )
                .keyboardType(.numberPad)

                Text("¿Necesitas cambiar tu nombre o cédula? Hazlo desde Editar perfil.")
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
                detailLine(
                    title: "Murco Loyalty",
                    value: "-\(viewModel.state.rewardPreview.discountAmount.priceText)",
                    accent: true
                )
            }

            Divider().overlay(palette.stroke)

            detailLine(
                title: "Total",
                value: effectiveTotal.priceText,
                emphasized: true
            )
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
                    Text("Total a pagar")
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
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Confirmar pedido")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
            .disabled(cartManager.isEmpty || viewModel.state.isSubmitting)
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private func syncProfileFieldsFromSession() {
        guard let profile = authenticatedProfile else { return }

        if cartManager.clientId != profile.nationalId {
            cartManager.clientId = profile.nationalId
        }

        if cartManager.clientName != profile.fullName {
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
                .foregroundStyle(
                    accent
                    ? palette.success
                    : (secondary ? palette.textSecondary : palette.textPrimary)
                )

            Spacer()

            Text(value)
                .font(emphasized ? .headline.bold() : .subheadline.weight(.semibold))
                .foregroundStyle(
                    accent
                    ? palette.success
                    : (secondary ? palette.textSecondary : palette.textPrimary)
                )
        }
    }
}
