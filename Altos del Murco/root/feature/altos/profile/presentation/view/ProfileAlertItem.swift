//
//  ProfileAlertItem.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

struct ProfileAlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
