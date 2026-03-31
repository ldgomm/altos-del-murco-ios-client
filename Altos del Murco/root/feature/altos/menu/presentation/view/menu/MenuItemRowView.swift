//
//  MenuItemRowView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct MenuItemRowView: View {
    let item: MenuItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 24))
                        .foregroundStyle(.gray)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(item.isAvailable ? .primary : .secondary)
                    
                    if item.isFeatured {
                        Text("Popular")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    
                    if item.hasOffer {
                        Text("Offer")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                
                HStack(spacing: 8) {
                    if item.hasOffer, let offerPrice = item.offerPrice {
                        Text(item.price.priceText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .strikethrough()
                        
                        Text(offerPrice.priceText)
                            .font(.headline)
                            .fontWeight(.bold)
                    } else {
                        Text(item.price.priceText)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    if !item.isAvailable {
                        Text("Sold out")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
}
