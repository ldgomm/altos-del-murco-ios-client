//
//  CheckoutState.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct CheckoutState {
    var isSubmitting = false
    var createdOrder: Order?
    var errorMessage: String?
}
