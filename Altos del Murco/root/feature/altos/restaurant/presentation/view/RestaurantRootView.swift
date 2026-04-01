//
//  RestaurantRootView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct RestaurantRootView: View {
    @State private var path = NavigationPath()
    
    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var checkoutViewModel: CheckoutViewModel
    
    var body: some View {
        NavigationStack(path: $path) {
            MenuListView(
                sections: MenuMockData.sections,
//                ordersViewModel: ordersViewModel,
                checkoutViewModel: checkoutViewModel,
                path: $path
            )
        }
    }
}
