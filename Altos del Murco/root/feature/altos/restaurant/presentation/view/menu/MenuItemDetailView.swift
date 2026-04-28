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
    let rewardPresentationProvider: (MenuItem, Int) -> RewardPresentation?
    let displayedPriceProvider: (MenuItem, Int) -> Double
    let incrementalDiscountProvider: (MenuItem, Int) -> Double

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

    private var rewardPresentation: RewardPresentation? {
        rewardPresentationProvider(item, quantity)
    }

    private var displayedPrice: Double {
        displayedPriceProvider(item, quantity)
    }

    private var incrementalDiscount: Double {
        incrementalDiscountProvider(item, quantity)
    }

    private var baseSubtotal: Double {
        item.finalPrice * Double(quantity)
    }

    private var currentTotal: Double {
        incrementalDiscount > 0 ? displayedPrice : baseSubtotal
    }

    private var heroShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: AppTheme.Radius.xLarge,
            style: .continuous
        )
    }

    init(
        item: MenuItem,
        categoryTitle: String,
        rewardPresentationProvider: @escaping (MenuItem, Int) -> RewardPresentation?,
        displayedPriceProvider: @escaping (MenuItem, Int) -> Double,
        incrementalDiscountProvider: @escaping (MenuItem, Int) -> Double
    ) {
        self.item = item
        self.categoryTitle = categoryTitle
        self.rewardPresentationProvider = rewardPresentationProvider
        self.displayedPriceProvider = displayedPriceProvider
        self.incrementalDiscountProvider = incrementalDiscountProvider
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                heroSection

                if !item.canBeOrdered {
                    availabilityWarningCard
                }

                detailsSection
                Divider()
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.restaurant)
//        .safeAreaInset(edge: .bottom) {
//            
//        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            heroImageLayer
            heroGradientOverlay
            heroDecorations
            heroContent
        }
        .frame(height: 320)
        .clipShape(heroShape)
        .overlay {
            heroShape
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18), lineWidth: 1)
        }
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.30 : 0.14),
            radius: 22,
            x: 0,
            y: 12
        )
    }

    @ViewBuilder
    private var heroImageLayer: some View {
        if let imageURL = item.imageURL,
           let url = URL(string: imageURL) {
            GeometryReader { proxy in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        heroImageLoadingView
                            .frame(width: proxy.size.width, height: proxy.size.height)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()

                    case .failure:
                        heroImagePlaceholder
                            .frame(width: proxy.size.width, height: proxy.size.height)

                    @unknown default:
                        heroImagePlaceholder
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }
            }
        } else {
            heroImagePlaceholder
        }
    }

    private var heroImageLoadingView: some View {
        ZStack {
            palette.heroGradient

            VStack(spacing: 12) {
                ProgressView()
                    .tint(palette.primary)

                Text("Preparando imagen")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.onPrimary.opacity(0.82))
            }
        }
    }

    private var heroImagePlaceholder: some View {
        ZStack {
            palette.heroGradient

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.16))
                .frame(width: 190, height: 190)
                .blur(radius: 12)
                .offset(x: 70, y: -70)

            VStack(spacing: 14) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(palette.onPrimary.opacity(0.92))

                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(palette.onPrimary.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
        }
    }

    private var heroGradientOverlay: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.05),
                .black.opacity(colorScheme == .dark ? 0.30 : 0.18),
                .black.opacity(0.78)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var heroDecorations: some View {
        VStack {
            HStack {
                if item.isFeatured {
                    BrandBadge(theme: .restaurant, title: "Popular", selected: true)
                }

                Spacer()

                Text(item.stockLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.canBeOrdered ? .white : palette.destructive)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(item.canBeOrdered ? .white.opacity(0.18) : .white.opacity(0.94))
                    )
                    .overlay {
                        Capsule()
                            .stroke(.white.opacity(0.22), lineWidth: 1)
                    }
            }

            Spacer()
        }
        .padding(18)
    }

    private var heroContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Label(categoryTitle, systemImage: "tag.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Text(item.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.90))
                    .lineLimit(2)
            }

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                if incrementalDiscount > 0 {
                    Text(baseSubtotal.priceText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                        .strikethrough()

                    Text(displayedPrice.priceText)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    BrandBadge(theme: .restaurant, title: "Premio", selected: true)
                } else if item.hasOffer, let offerPrice = item.offerPrice {
                    Text(item.price.priceText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                        .strikethrough()

                    Text(offerPrice.priceText)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    BrandBadge(theme: .restaurant, title: "Oferta", selected: true)
                } else {
                    Text(item.finalPrice.priceText)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                Spacer()
            }
        }
        .padding(20)
    }

    private var availabilityWarningCard: some View {
        HStack(alignment: .top, spacing: 12) {
            BrandIconBubble(
                theme: .restaurant,
                systemImage: "exclamationmark.triangle.fill",
                size: 42
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("No disponible por ahora")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text("Este producto no se puede agregar al carrito en este momento. Puedes revisar otros platos disponibles del menú.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            quickInfoCard

            if let rewardPresentation {
                rewardsCard(rewardPresentation)
            }

            descriptionCard
            ingredientsCard
            priceCard
            quantityCard
            notesCard
        }
    }

    private var quickInfoCard: some View {
        HStack(spacing: 10) {
            infoPill(
                title: "Categoría",
                value: categoryTitle,
                systemImage: "tag.fill"
            )

            infoPill(
                title: "Stock",
                value: item.stockLabel,
                systemImage: item.canBeOrdered ? "checkmark.circle.fill" : "xmark.circle.fill"
            )

            infoPill(
                title: "Cantidad",
                value: "\(quantity)",
                systemImage: "number.circle.fill"
            )
        }
    }

    private func infoPill(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.primary)

            Text(value)
                .font(.caption.bold())
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(palette.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func rewardsCard(_ reward: RewardPresentation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Premio disponible",
                subtitle: "Este beneficio se refleja automáticamente en el valor mostrado."
            )

            HStack(alignment: .top, spacing: 12) {
                BrandBadge(theme: .restaurant, title: reward.badge, selected: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Text(reward.message)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                if let amountText = reward.amountText {
                    Text("-\(amountText)")
                        .font(.caption.bold())
                        .foregroundStyle(palette.success)
                }
            }
        }
        .appCardStyle(.restaurant)
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Descripción",
                subtitle: "Conoce más sobre este plato."
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
                title: "Ingredientes",
                subtitle: "Componentes frescos y acompañamientos."
            )

            if item.ingredients.isEmpty {
                Text("No hay ingredientes detallados para este plato.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(item.ingredients, id: \.self) { ingredient in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(palette.primary)
                                .frame(width: 6, height: 6)

                            Text(ingredient)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.textSecondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(palette.elevatedCard)
                        )
                        .overlay(
                            Capsule()
                                .stroke(palette.stroke, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .appCardStyle(.restaurant)
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Precio",
                subtitle: priceSubtitle
            )

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                if incrementalDiscount > 0 {
                    Text(baseSubtotal.priceText)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(palette.textTertiary)
                        .strikethrough()

                    Text(displayedPrice.priceText)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.success)
                } else if item.hasOffer, let offerPrice = item.offerPrice {
                    Text((item.price * Double(quantity)).priceText)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(palette.textTertiary)
                        .strikethrough()

                    Text((offerPrice * Double(quantity)).priceText)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                } else {
                    Text(baseSubtotal.priceText)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                }

                Spacer()
            }

            if quantity > 1 {
                Text("Unitario: \(item.finalPrice.priceText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.restaurant)
    }

    private var priceSubtitle: String {
        if incrementalDiscount > 0 {
            return "Incluye el beneficio aplicado por Murco Loyalty."
        }

        if item.hasOffer {
            return "Oferta especial disponible."
        }

        return "Precio regular actual."
    }

    private var quantityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Cantidad",
                subtitle: "Elige cuántos quieres añadir."
            )

            QuantitySelectorView(
                quantity: $quantity,
                isEnabled: item.canBeOrdered,
                theme: .restaurant,
                minimum: 1,
                maximum: max(1, item.remainingQuantity)
            )
            .opacity(item.canBeOrdered ? 1 : 0.55)
        }
        .appCardStyle(.restaurant)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Notas",
                subtitle: "Instrucciones especiales para la cocina."
            )

            TextField("Agrega alguna nota especial (opcional)", text: $notesText, axis: .vertical)
                .appTextFieldStyle(.restaurant)
                .lineLimit(3, reservesSpace: true)
                .disabled(!item.canBeOrdered)
                .opacity(item.canBeOrdered ? 1 : 0.55)
        }
        .appCardStyle(.restaurant)
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if showAddedMessage {
                Text("El pedido ha sido agregado")
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
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.canBeOrdered ? "Total" : "No disponible")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.textSecondary)

                        if incrementalDiscount > 0 {
                            Text("Incluye premio")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.success)
                        }

                        if incrementalDiscount > 0 {
                            Text(baseSubtotal.priceText)
                                .font(.caption)
                                .foregroundStyle(palette.textTertiary)
                                .strikethrough()
                        }

                        Text(currentTotal.priceText)
                            .font(.title3.bold())
                            .foregroundStyle(item.canBeOrdered ? palette.textPrimary : palette.textTertiary)
                    }

                    Spacer()

                    Text("\(quantity)x")
                        .font(.caption.bold())
                        .foregroundStyle(palette.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(palette.elevatedCard)
                        )
                        .overlay(
                            Capsule()
                                .stroke(palette.stroke, lineWidth: 1)
                        )
                }

                Button {
                    let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

                    let didAdd = cartManager.add(
                        item: item,
                        quantity: quantity,
                        notes: finalNotes
                    )

                    guard didAdd else {
                        return
                    }

                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAddedMessage = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAddedMessage = false
                        }

                        dismiss()
                    }
                } label: {
                    Label("Agregar al carrito", systemImage: "cart.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
                .disabled(!item.canBeOrdered)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
    }
}
