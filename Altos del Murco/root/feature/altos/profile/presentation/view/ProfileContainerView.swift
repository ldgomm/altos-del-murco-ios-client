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
                NavigationStack {
                    ZStack {
                        BrandScreenBackground(theme: .neutral)
                        
                        VStack(spacing: 18) {
                            ProgressView()
                                .scaleEffect(1.1)
                            
                            VStack(spacing: 6) {
                                Text("Loading profile...")
                                    .font(.headline)
                                
                                Text("Preparing your account and preferences.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .appCardStyle(.neutral, emphasized: true)
                        .padding()
                    }
                    .navigationTitle("Profile")
                }
                .appScreenStyle(.neutral)
            }
        }
    }
}
