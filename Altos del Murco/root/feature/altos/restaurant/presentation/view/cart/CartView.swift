//
//  CartView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct CartView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    let nationalId: String

    @EnvironmentObject private var cartManager: CartManager
    @State private var showClearCartAlert = false

    private var rewardDiscountByMenuItemId: [String: Double] {
        viewModel.allocatedDiscountByMenuItemId()
    }

    private var effectiveTotal: Double {
        viewModel.effectiveTotal(for: cartManager.subtotal)
    }

    var body: some View {
        VStack(spacing: 0) {
            if cartManager.isEmpty {
                ContentUnavailableView(
                    "Tu carrito está vacío",
                    systemImage: "cart",
                    description: Text("Agrega algunos platos deliciosos del menú.")
                )
            } else {
                List {
                    Section("Productos") {
                        ForEach(cartManager.items) { cartItem in
                            RewardAwareCartItemRow(
                                cartItem: cartItem,
                                allocatedDiscount: allocatedDiscount(for: cartItem)
                            )
                        }
                        .onDelete(perform: deleteItems)
                    }

                    Section("Resumen") {
                        summaryRow("Subtotal", cartManager.subtotal.priceText, emphasized: true)

                        if viewModel.state.rewardPreview.discountAmount > 0 {
                            summaryRow(
                                "Murco Loyalty",
                                "-\(viewModel.state.rewardPreview.discountAmount.priceText)",
                                accent: true
                            )
                        }

                        summaryRow("Productos", "\(cartManager.totalItems)", secondary: true)

                        Divider()

                        summaryRow("Total", effectiveTotal.priceText, emphasized: true)
                    }

                    if !viewModel.state.rewardPreview.appliedRewards.isEmpty {
                        Section("Premios aplicados") {
                            ForEach(viewModel.state.rewardPreview.appliedRewards) { reward in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(reward.title)
                                        .font(.subheadline.bold())

                                    Text(reward.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text("-\(reward.amount.priceText)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.green)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Carrito")
        .appScreenStyle(.restaurant)
        .onAppear {
            viewModel.onAppear(nationalId: nationalId)
        }
        .onChange(of: nationalId) { _, value in
            viewModel.onAppear(nationalId: value)
        }
        .toolbar {
            if !cartManager.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Vaciar") {
                        showClearCartAlert = true
                    }
                }
            }
        }
        .alert("¿Vaciar carrito?", isPresented: $showClearCartAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Vaciar", role: .destructive) {
                cartManager.clear()
            }
        } message: {
            Text("¿Estás seguro de que quieres eliminar todos los productos de tu carrito?")
        }
        .safeAreaInset(edge: .bottom) {
            if !cartManager.isEmpty {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if viewModel.state.rewardPreview.discountAmount > 0 {
                                Text("Incluye Murco Loyalty")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.green)
                            }

                            Text(effectiveTotal.priceText)
                                .font(.title3)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        NavigationLink(value: Route.checkout) {
                            Text("Finalizar compra")
                                .font(.headline)
                                .frame(minWidth: 140)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .background(Color.primary)
                                .foregroundStyle(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(.ultraThinMaterial)
                }
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let itemId = cartManager.items[index].menuItem.id
            cartManager.remove(itemId: itemId)
        }
    }

    private func allocatedDiscount(for cartItem: CartItem) -> Double {
        let totalDiscount = rewardDiscountByMenuItemId[cartItem.menuItem.id, default: 0]
        guard totalDiscount > 0 else { return 0 }

        let siblingRows = cartManager.items.filter { $0.menuItem.id == cartItem.menuItem.id }
        let totalSiblingSubtotal = siblingRows.reduce(0) { $0 + $1.totalPrice }
        guard totalSiblingSubtotal > 0 else { return 0 }

        if siblingRows.count == 1 {
            return totalDiscount
        }

        let share = cartItem.totalPrice / totalSiblingSubtotal
        return ((totalDiscount * share) * 100).rounded() / 100
    }

    private func summaryRow(
        _ title: String,
        _ value: String,
        emphasized: Bool = false,
        secondary: Bool = false,
        accent: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(emphasized ? .headline : .body)
                .foregroundStyle(accent ? .green : (secondary ? .secondary : .primary))

            Spacer()

            Text(value)
                .font(emphasized ? .headline : .body)
                .fontWeight(emphasized ? .bold : .semibold)
                .foregroundStyle(accent ? .green : (secondary ? .secondary : .primary))
        }
    }
}

private struct RewardAwareCartItemRow: View {
    let cartItem: CartItem
    let allocatedDiscount: Double

    @EnvironmentObject private var cartManager: CartManager

    private var discountedTotal: Double {
        max(0, cartItem.totalPrice - allocatedDiscount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 22))
                            .foregroundStyle(.gray)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(cartItem.menuItem.name)
                        .font(.headline)

                    Text(cartItem.menuItem.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if !cartItem.menuItem.canBeOrdered {
                        Text("Agotado")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    } else if cartItem.quantity >= cartItem.menuItem.remainingQuantity {
                        Text("Límite alcanzado")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }

                    if let notes = cartItem.notes,
                       !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(notes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        if cartItem.menuItem.hasOffer {
                            Text(cartItem.menuItem.price.priceText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .strikethrough()

                            Text(cartItem.menuItem.finalPrice.priceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        } else {
                            Text(cartItem.menuItem.finalPrice.priceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        if allocatedDiscount > 0 {
                            Text("• Premio -\(allocatedDiscount.priceText)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    }
                }

                Spacer()
            }

            HStack {
                HStack(spacing: 14) {
                    Button {
                        cartManager.decreaseQuantity(for: cartItem.menuItem.id)
                    } label: {
                        Image(systemName: "minus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)

                    Text("\(cartItem.quantity)")
                        .font(.headline)
                        .frame(minWidth: 24)

                    Button {
                        cartManager.increaseQuantity(for: cartItem.menuItem.id)
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(!cartItem.menuItem.canBeOrdered || cartItem.quantity >= cartItem.menuItem.remainingQuantity)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(allocatedDiscount > 0 ? "Total con premio" : "Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if allocatedDiscount > 0 {
                        Text(cartItem.totalPrice.priceText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }

                    Text(discountedTotal.priceText)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
