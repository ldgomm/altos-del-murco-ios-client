//
//  MenuListenerToken.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import FirebaseFirestore

final class MenuListenerToken: MenuListenerTokenable {
    private var registration: ListenerRegistration?

    init(registration: ListenerRegistration) {
        self.registration = registration
    }

    func remove() {
        registration?.remove()
        registration = nil
    }
}
