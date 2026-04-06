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

    @State private var selectedCategoryId: String?

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
            LazyVStack(alignment: .leading, spacing: 20) {
                if !featuredItems.isEmpty {
                    featuredCarousel
                }

                categorySelector

                ForEach(filteredSections) { section in
                    sectionContent(section)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Restaurant")
        .task {
            if selectedCategoryId == nil {
                selectedCategoryId = categories.first?.id
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(value: Route.cart) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart")
                            .font(.system(size: 17))

                        if cartManager.totalItems > 0 {
                            Text("\(cartManager.totalItems)")
                                .font(.system(size: 8, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                                .frame(minWidth: 14, minHeight: 14)
                                .padding(.horizontal, cartManager.totalItems > 9 ? 3 : 0)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 2, y: -4)
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
                CheckoutView(viewModel: checkoutViewModel)
            case let .orderSuccess(order):
                OrderSuccessView(order: order)
            }
        }
    }
    
    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular")
                .font(.title3.bold())
                .padding(.horizontal)

            TabView {
                ForEach(featuredItems) { item in
                    NavigationLink(value: Route.menuDetail(item, categoryTitle(for: item.categoryId))) {
                        FeaturedMenuCard(item: item)
                            .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 210)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }
    
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Browse by category")
                .font(.headline)
                .padding(.horizontal)

            Picker("Category", selection: Binding(
                get: { selectedCategoryId ?? "" },
                set: { selectedCategoryId = $0 }
            )) {
                ForEach(categories) { category in
                    Text(category.title).tag(category.id)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func sectionContent(_ section: MenuSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.category.title)
                .font(.title3.bold())
                .padding(.horizontal)

            LazyVStack(spacing: 12) {
                ForEach(section.items) { item in
                    NavigationLink(value: Route.menuDetail(item, section.category.title)) {
                        MenuItemRowView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func categoryTitle(for categoryId: String) -> String {
        categories.first(where: { $0.id == categoryId })?.title ?? ""
    }
}

struct FeaturedMenuCard: View {
    let item: MenuItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .frame(maxWidth: .infinity)
                .overlay {
                    if let imageURL = item.imageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)

                Text(String(format: "$%.2f", item.finalPrice))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .padding()
        }
        .frame(height: 190)
    }
}
