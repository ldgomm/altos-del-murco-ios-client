//
//  MenuListView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct MenuListView: View {
    let sections: [MenuSection]
    @ObservedObject var checkoutViewModel: CheckoutViewModel
    @EnvironmentObject private var cartManager: CartManager
    @Binding var path: NavigationPath
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedCategoryId: String?
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var categories: [MenuCategory] {
        sections.map(\.category)
    }

    private var featuredItems: [MenuItem] {
        sections
            .flatMap(\.items)
            .filter(\.isFeatured)
    }

    private var filteredSections: [MenuSection] {
        guard let selectedCategoryId else { return sections }
        return sections.filter { $0.category.id == selectedCategoryId }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                headerSection
                
                if !featuredItems.isEmpty {
                    featuredCarousel
                }

                categorySelector

                ForEach(filteredSections) { section in
                    sectionContent(section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("Restaurant")
        .navigationBarTitleDisplayMode(.large)
        .appScreenStyle(.restaurant)
        .task {
            if selectedCategoryId == nil {
                selectedCategoryId = categories.first?.id
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(value: Route.cart) {
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            Circle()
                                .fill(palette.chipGradient)
                                .frame(width: 34, height: 34)
                            
                            Image(systemName: "cart.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(palette.primary)
                        }

                        if cartManager.totalItems > 0 {
                            Text("\(cartManager.totalItems)")
                                .font(.system(size: 9, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .padding(.horizontal, cartManager.totalItems > 9 ? 4 : 0)
                                .background(palette.destructive)
                                .clipShape(Capsule())
                                .offset(x: 5, y: -4)
                        }
                    }
                }
            }
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case let .menuDetail(item, categoryTitle):
                MenuItemDetailView(item: item, categoryTitle: categoryTitle)
            case .cart:
                CartView()
            case .checkout:
                CheckoutView(viewModel: checkoutViewModel, path: $path)
            case let .orderSuccess(order):
                OrderSuccessView(order: order, path: $path)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Flavors from Altos del Murco")
                .font(.title2.bold())
                .foregroundStyle(palette.textPrimary)
            
            Text("Explore our charcoal-grilled dishes, house specials, drinks, and more.")
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(.restaurant, emphasized: false)
    }
    
    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Popular",
                subtitle: "Customer favorites and featured dishes"
            )

            TabView {
                ForEach(featuredItems) { item in
                    NavigationLink(value: Route.menuDetail(item, categoryTitle(for: item.categoryId))) {
                        FeaturedMenuCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 220)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }
    
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Browse by category"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategoryId = category.id
                            }
                        } label: {
                            BrandBadge(
                                theme: .restaurant,
                                title: category.title,
                                selected: selectedCategoryId == category.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    @ViewBuilder
    private func sectionContent(_ section: MenuSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .restaurant,
                title: section.category.title
            )

            LazyVStack(spacing: 12) {
                ForEach(section.items) { item in
                    NavigationLink(value: Route.menuDetail(item, section.category.title)) {
                        MenuItemRowView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func categoryTitle(for categoryId: String) -> String {
        categories.first(where: { $0.id == categoryId })?.title ?? ""
    }
}

struct FeaturedMenuCard: View {
    let item: MenuItem
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.cardGradient)

            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .overlay {
                    if let imageURL = item.imageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    palette.card
                                    ProgressView()
                                        .tint(palette.primary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                
                            case .failure:
                                ZStack {
                                    palette.card
                                    
                                    VStack(spacing: 10) {
                                        Image(systemName: "fork.knife.circle.fill")
                                            .font(.system(size: 34))
                                            .foregroundStyle(palette.primary)
                                        
                                        Text(item.name)
                                            .font(.headline)
                                            .foregroundStyle(palette.textSecondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                }
                                
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                        )
                    }
                }

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(colorScheme == .dark ? 0.35 : 0.15),
                    .black.opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    BrandBadge(theme: .restaurant, title: "Featured", selected: true)
                    Spacer()
                }
                
                Text(item.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)

                Text(String(format: "$%.2f", item.finalPrice))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(18)
        }
        .frame(height: 200)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .stroke(palette.stroke.opacity(0.6), lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.22 : 0.12),
            radius: 16,
            x: 0,
            y: 10
        )
    }
}
