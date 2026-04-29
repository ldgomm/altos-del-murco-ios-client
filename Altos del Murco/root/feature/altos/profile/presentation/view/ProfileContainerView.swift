//
//  ProfileContainerView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct ProfileContainerView: View {
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @EnvironmentObject private var appPreferences: AppPreferences

    var body: some View {
        Group {
            if let factory = sessionViewModel.makeProfileViewModelFactory(appPreferences: appPreferences) {
                ProfileView(viewModelFactory: factory)
                    .appScreenStyle(.neutral)
            } else {
                ProtectedAccessRequiredView(
                    title: "Inicia sesión para ver tu perfil",
                    message: "Tu perfil, recompensas y configuración de cuenta requieren iniciar sesión. El menú y las experiencias se pueden explorar sin cuenta.",
                    systemImage: "person.crop.circle",
                    theme: .neutral
                )
            }
        }
    }
}
