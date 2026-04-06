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
            } else {
                NavigationStack {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading profile...")
                            .foregroundStyle(.secondary)
                    }
                    .navigationTitle("Profile")
                }
            }
        }
    }
}
