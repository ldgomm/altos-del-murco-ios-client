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
            isPresented: .constant(viewModel.state.errorMessage != nil),
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
                
                HStack(alignment: .top, spacing: 12) {
                    BrandIconBubble(theme: .restaurant, systemImage: "person.crop.circle.badge.checkmark", size: 38)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("¿Necesitas actualizar tu información?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)
                        
                        Text("Por favor, cambia tu nombre o cédula desde la página Editar perfil.")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .fill(palette.elevatedCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .stroke(palette.stroke, lineWidth: 1)
                )
                
                HStack(spacing: 12) {
                    BrandIconBubble(theme: .restaurant, systemImage: "clock.fill", size: 38)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hora del pedido")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)
                        
                        Text(cartManager.orderCreatedAt.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .fill(palette.elevatedCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .stroke(palette.stroke, lineWidth: 1)
                )
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Resumen",
                subtitle: "Revisión rápida del pedido antes de confirmar."
            )
            
            VStack(spacing: 14) {
                summaryRow(
                    title: "Productos",
                    value: "\(cartManager.totalItems)",
                    systemImage: "fork.knife"
                )
                
                summaryRow(
                    title: "Total",
                    value: cartManager.totalAmount.priceText,
                    systemImage: "dollarsign.circle.fill",
                    isHighlighted: true
                )
            }
        }
        .appCardStyle(.restaurant)
    }
    
    private var confirmSection: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.onEvent(.confirmTapped)
            } label: {
                Group {
                    if viewModel.state.isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Confirmar pedido")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
            .disabled(viewModel.state.isSubmitting)
            
            Text("Revisa los datos cuidadosamente antes de crear el pedido.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .appCardStyle(.restaurant)
    }
    
    private func themedField(
        title: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
            
            TextField(title, text: text)
                .appTextFieldStyle(.restaurant)
        }
    }
    
    private func summaryRow(
        title: String,
        value: String,
        systemImage: String,
        isHighlighted: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            BrandIconBubble(theme: .restaurant, systemImage: systemImage, size: 40)
            
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(isHighlighted ? .headline.bold() : .headline)
                .foregroundStyle(isHighlighted ? palette.primary : palette.textPrimary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
    
    private func syncProfileFieldsFromSession() {
        guard let profile = authenticatedProfile else { return }
        
        if cartManager.clientId != profile.nationalId {
            cartManager.updateClientId(profile.nationalId)
        }
        
        if cartManager.clientName != profile.fullName {
            cartManager.updateClientName(profile.fullName)
        }
    }
    
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Tus premios",
                subtitle: "Se aplican automáticamente si el pedido cumple la regla."
            )

            if viewModel.state.isLoadingRewards {
                ProgressView("Calculando premios...")
            } else if viewModel.state.rewardPreview.appliedRewards.isEmpty {
                Text("No hay premios automáticos aplicables para este pedido.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.state.rewardPreview.appliedRewards) { reward in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reward.title).font(.headline)
                            Text(reward.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("-\(reward.amount.priceText)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                }
            }
        }
        .appCardStyle(.restaurant)
    }
}
