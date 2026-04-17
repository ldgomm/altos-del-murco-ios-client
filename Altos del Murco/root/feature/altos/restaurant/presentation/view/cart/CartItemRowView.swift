//
//  CartItemRowView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct CartItemRowView: View {
    let cartItem: CartItem
    
    @EnvironmentObject private var cartManager: CartManager
    
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
                    
                    if let notes = cartItem.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(cartItem.totalPrice.priceText)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            
            
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
