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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var quantity: Int = 1
    @State private var notesText: String = ""
    @State private var showAddedMessage = false
    
    private let theme: AppSectionTheme = .restaurant
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroSection
                detailsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .navigationTitle("Dish")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.restaurant)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }
    
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.heroGradient)
                .frame(height: 260)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                        .fill(.black.opacity(colorScheme == .dark ? 0.08 : 0.02))
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(palette.glow.opacity(colorScheme == .dark ? 0.30 : 0.18))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                        .offset(x: 24, y: -24)
                }
            
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    BrandIconBubble(theme: .restaurant, systemImage: "fork.knife", size: 60)
                    
                    Spacer()
                    
                    if item.isFeatured {
                        BrandBadge(theme: .restaurant, title: "Popular", selected: true)
                    }
                }
                
                Spacer()
                
                Text(item.name)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.onPrimary)
                
                HStack(spacing: 10) {
                    Label(categoryTitle, systemImage: "tag.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.onPrimary.opacity(0.92))
                    
                    Text(item.stockLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.canBeOrdered ? palette.onPrimary : palette.destructive)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            item.canBeOrdered
                            ? .white.opacity(0.18)
                            : .white.opacity(0.92)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(20)
        }
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.28 : 0.12),
            radius: 18,
            x: 0,
            y: 10
        )
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            descriptionCard
            ingredientsCard
            priceCard
            quantityCard
            notesCard
        }
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Description",
                subtitle: "A closer look at this dish."
            )
            
            Text(item.description)
                .font(.body)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCardStyle(.restaurant, emphasized: false)
    }
    
    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Ingredients",
                subtitle: "Fresh components and accompaniments."
            )
            
            ForEach(item.ingredients, id: \.self) { ingredient in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(palette.accent)
                        .frame(width: 7, height: 7)
                        .padding(.top, 7)
                    
                    Text(ingredient)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
        .appCardStyle(.restaurant)
    }
    
    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Price",
                subtitle: item.hasOffer ? "Special offer available." : "Current regular price."
            )
            
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                if item.hasOffer, let offerPrice = item.offerPrice {
                    Text(item.price.priceText)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(palette.textTertiary)
                        .strikethrough()
                    
                    Text(offerPrice.priceText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                } else {
                    Text(item.price.priceText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                }
            }
        }
        .appCardStyle(.restaurant)
    }
    
    private var quantityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Quantity",
                subtitle: "Choose how many you want to add."
            )
            
            QuantitySelectorView(
                quantity: $quantity,
                isEnabled: item.canBeOrdered,
                theme: .restaurant,
                minimum: 1,
                maximum: item.remainingQuantity
            )
            .opacity(item.isAvailable ? 1 : 0.55)
        }
        .appCardStyle(.restaurant)
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Notes",
                subtitle: "Special instructions for the kitchen."
            )
            
            TextField("Add any special notes (optional)", text: $notesText, axis: .vertical)
                .appTextFieldStyle(.restaurant)
                .lineLimit(3, reservesSpace: true)
                .disabled(!item.isAvailable)
                .opacity(item.isAvailable ? 1 : 0.55)
        }
        .appCardStyle(.restaurant)
    }
    
    private var bottomBar: some View {
        VStack(spacing: 12) {
            if showAddedMessage {
                Text("Order has been added")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(palette.success)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.textSecondary)
                        
                        Text((Double(quantity) * item.finalPrice).priceText)
                            .font(.title3.bold())
                            .foregroundStyle(palette.textPrimary)
                    }
                    
                    Spacer()
                }
                
                if !item.canBeOrdered {
                    Text("No quedan platos disponibles por ahora.")
                        .font(.footnote)
                        .foregroundStyle(palette.destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button {
                    cartManager.add(item: item, quantity: quantity, notes: notesText)
                    
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAddedMessage = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAddedMessage = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            dismiss()
                        }
                    }
                } label: {
                    Text(item.canBeOrdered ? "Añadir a la orden" : "Agotado")
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
                .disabled(!item.canBeOrdered)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(palette.elevatedCard.opacity(colorScheme == .dark ? 0.96 : 0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(
            Rectangle()
                .fill(palette.background.opacity(colorScheme == .dark ? 0.92 : 0.85))
                .ignoresSafeArea()
        )
    }
}
