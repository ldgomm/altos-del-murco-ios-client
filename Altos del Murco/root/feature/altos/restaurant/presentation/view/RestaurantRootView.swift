//
//  RestaurantRootView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct RestaurantRootView: View {
    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var checkoutViewModel: CheckoutViewModel
    
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            MenuListView(
                sections: MenuMockData.sections,
                checkoutViewModel: checkoutViewModel,
                ordersViewModel: ordersViewModel,
                path: $path
            )
        }
    }
}
