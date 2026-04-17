//
//  MenuServiceable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import Foundation

protocol MenuServiceable {
    func observeMenu(
        onChange: @escaping (Result<[MenuSection], Error>) -> Void
    ) -> MenuListenerTokenable
}

protocol MenuListenerTokenable {
    func remove()
}
