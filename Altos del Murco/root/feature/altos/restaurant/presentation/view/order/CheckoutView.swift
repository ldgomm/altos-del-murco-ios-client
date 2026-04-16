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
    
    @Binding var path: NavigationPath
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                clientDetailsSection
                summarySection
                confirmSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .navigationTitle("Checkout")
        .appScreenStyle(.restaurant)
        .alert(
            "Error",
            isPresented: .constant(viewModel.state.errorMessage != nil),
            actions: {
                Button("OK") {
                    viewModel.clearError()
                }
            },
            message: {
                Text(viewModel.state.errorMessage ?? "")
            }
        )
        .onChange(of: viewModel.state.createdOrder) { _, order in
            guard let order else { return }
            path.append(Route.orderSuccess(order))
        }
    }
    
    private var clientDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Client Details",
                subtitle: "Confirm who the order belongs to before sending it to the kitchen."
            )
            
            VStack(spacing: 14) {
                themedField(
                    title: "Cédula",
                    text: Binding(
                        get: { cartManager.clientId ?? "" },
                        set: { cartManager.updateClientId($0) }
                    )
                )
                
                themedField(
                    title: "Nombre",
                    text: Binding(
                        get: { cartManager.clientName },
                        set: { cartManager.updateClientName($0) }
                    )
                )
                
                themedField(
                    title: "Table number",
                    text: Binding(
                        get: { cartManager.tableNumber },
                        set: { cartManager.updateTableNumber($0) }
                    )
                )
                .keyboardType(.numberPad)
                
                HStack(spacing: 12) {
                    BrandIconBubble(theme: .restaurant, systemImage: "clock.fill", size: 38)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Order time")
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
                title: "Summary",
                subtitle: "Quick review of the order before confirming."
            )
            
            VStack(spacing: 14) {
                summaryRow(
                    title: "Items",
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
                        Text("Confirm Order")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
            .disabled(viewModel.state.isSubmitting)
            
            Text("Review the data carefully before creating the order.")
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
}
