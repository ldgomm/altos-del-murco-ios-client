//
//  MenuItemView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct MenuItemDetailView: View {
    var item: MenuItem
    let categoryTitle: String
    
    @EnvironmentObject private var cartManager: CartManager
    @State private var quantity: Int = 1
    @State private var notesText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 240)
                    
                    Image(systemName: "fork.knife")
                        .font(.system(size: 56))
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(item.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if item.isFeatured {
                            Text("Popular")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Label(categoryTitle, systemImage: "tag")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if !item.isAvailable {
                        Text("Currently unavailable")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                    
                    Text(item.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .font(.headline)
                        
                        ForEach(item.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 7)
                                
                                Text(ingredient)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Price")
                            .font(.headline)
                        
                        HStack(spacing: 10) {
                            if item.hasOffer, let offerPrice = item.offerPrice {
                                Text(item.price.priceText)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .strikethrough()
                                
                                Text(offerPrice.priceText)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            } else {
                                Text(item.price.priceText)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quantity")
                            .font(.headline)
                        
                        QuantitySelectorView(quantity: $quantity, isEnabled: item.isAvailable)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        TextField("Add any special notes (optional)", text: $notesText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3, reservesSpace: true)
                            .disabled(!item.isAvailable)
                            .opacity(item.isAvailable ? 1 : 0.6)
                    }
                    Divider()
                    
                }
                .padding(.horizontal)
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dish")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                HStack {
                    Text("Total")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text((Double(quantity) * item.finalPrice).priceText)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                
                Button {
                    cartManager.add(item: item, quantity: quantity, notes: notesText)
                } label: {
                    Text(item.isAvailable ? "Add to Order" : "Unavailable")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(item.isAvailable ? Color.primary : Color.gray.opacity(0.3))
                        .foregroundStyle(item.isAvailable ? Color.white : Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!item.isAvailable)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .padding(.top, 8)
            .background(.ultraThinMaterial)
        }
    }
}

