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
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.category.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
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
            }
            .padding(.vertical)
        }
        .navigationTitle("Restaurant")
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
}
