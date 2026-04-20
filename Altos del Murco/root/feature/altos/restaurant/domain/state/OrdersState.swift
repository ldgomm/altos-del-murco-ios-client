//
//  OrderState.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct OrdersState {
    var nationalId: String = ""
    var isLoading = false
    var orders: [Order] = []
    var errorMessage: String?
}
