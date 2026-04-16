//
//  Route.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum Route: Hashable {
    case menuDetail(MenuItem, String)
    case cart
    case checkout
    case reservationBuilder
    case orderSuccess(Order)
}
