//
//  AppearanceSettingsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        List {
            Section("Appearance") {
                ForEach(AppAppearance.allCases) { appearance in
                    Button {
                        viewModel.updateAppearance(appearance)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appearance.title)
                                    .foregroundStyle(.primary)

                                Text(appearance.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if viewModel.currentAppearance == appearance {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
