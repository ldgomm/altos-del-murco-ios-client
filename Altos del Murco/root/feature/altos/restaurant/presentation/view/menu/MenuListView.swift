//
//  MenuListView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct MenuListView: View {
    let sections: [MenuSection]
//    @ObservedObject var ordersViewModel: OrdersViewModel
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
//                Button {
//                    path.append(Route.orders)
//                } label: {
//                    Image(systemName: "clock.arrow.circlepath")
//                }
                
                NavigationLink(value: Route.cart) {
                    Image(systemName: "cart")
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
//            case .orders:
//                OrdersView(viewModel: ordersViewModel)
            case let .orderSuccess(order):
                OrderSuccessView(order: order)
            }
        }
//        .onAppear {
//            ordersViewModel.onEvent(.onAppear)
//        }
    }
}
