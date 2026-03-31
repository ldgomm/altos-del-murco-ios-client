//
//  CartView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject private var cartManager: CartManager
    @State private var showClearCartAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            if cartManager.isEmpty {
                ContentUnavailableView(
                    "Your cart is empty",
                    systemImage: "cart",
                    description: Text("Add some delicious dishes from the menu.")
                )
            } else {
                List {
                    Section("Items") {
                        ForEach(cartManager.items) { cartItem in
                            CartItemRowView(cartItem: cartItem)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    
                    Section("Summary") {
                        HStack {
                            Text("Subtotal")
                                .font(.headline)
                            Spacer()
                            Text(cartManager.subtotal.priceText)
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Items")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(cartManager.totalItems)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Cart")
        .toolbar {
            if !cartManager.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        showClearCartAlert = true
                    }
                }
            }
        }
        .alert("Clear cart?", isPresented: $showClearCartAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                cartManager.clear()
            }
        } message: {
            Text("Are you sure you want to remove all items from your cart?")
        }
        .safeAreaInset(edge: .bottom) {
            if !cartManager.isEmpty {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(cartManager.totalAmount.priceText)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        NavigationLink(value: Route.checkout) {
                            Text("Checkout")
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
}
