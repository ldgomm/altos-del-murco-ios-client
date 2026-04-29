//
//  CompleteProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct CompleteProfileView: View {
    @StateObject private var viewModel: CompleteProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private let theme: AppSectionTheme = .neutral
    
    init(viewModelFactory: @escaping () -> CompleteProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                personalInfoSection
                addressSection
                emergencySection

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(palette.destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appCardStyle(theme)
                }

                Text("You can browse the app without completing optional profile fields.")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(theme)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            BrandIconBubble(
                theme: theme,
                systemImage: "person.crop.circle.badge.checkmark",
                size: 62
            )

            Text("Complete your profile")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(palette.textPrimary)

            Text("Only your name is required here. Other details are optional or requested later when needed.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(theme, emphasized: true)
    }

    private var personalInfoSection: some View {
        VStack(spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Personal information",
                subtitle: "Only your name is required. National ID is requested later for real orders or services."
            )

            ProfileInputField(
                theme: theme,
                title: "Full name",
                placeholder: "Enter your full name",
                text: $viewModel.fullName,
                keyboardType: .default,
                autocapitalization: .words
            )

            ProfileInputField(
                theme: theme,
                title: "National unique number (optional here)",
                placeholder: "Example: 0501234567",
                text: $viewModel.nationalId,
                keyboardType: .numberPad,
                autocapitalization: .never
            )

            ProfileInputField(
                theme: theme,
                title: "Phone number (optional here)",
                placeholder: "Example: 0987654321",
                text: $viewModel.phoneNumber,
                keyboardType: .phonePad,
                autocapitalization: .never
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Birthday")
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.textPrimary)

                DatePicker(
                    "",
                    selection: $viewModel.birthday,
                    in: viewModel.validBirthdayRange,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(palette.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(minHeight: AppTheme.Metrics.fieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .fill(palette.elevatedCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .stroke(palette.stroke, lineWidth: 1)
                )
            }
        }
        .appCardStyle(theme)
    }

    private var addressSection: some View {
        VStack(spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Address (optional)",
                subtitle: "Optional. Use only if relevant to a future service."
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Address")
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.textPrimary)

                TextField("Street, reference, sector...", text: $viewModel.address, axis: .vertical)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .foregroundStyle(palette.textPrimary)
                    .tint(palette.primary)
                    .padding(16)
                    .frame(minHeight: 110, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
            }
        }
        .appCardStyle(theme)
    }

    private var emergencySection: some View {
        VStack(spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Emergency contact",
                subtitle: "Optional. Request only when directly relevant to a service."
            )

            ProfileInputField(
                theme: theme,
                title: "Emergency contact name (optional)",
                placeholder: "Who should we contact if needed?",
                text: $viewModel.emergencyContactName,
                keyboardType: .default,
                autocapitalization: .words
            )

            ProfileInputField(
                theme: theme,
                title: "Emergency contact phone (optional)",
                placeholder: "Example: 0999999999",
                text: $viewModel.emergencyContactPhone,
                keyboardType: .phonePad,
                autocapitalization: .never
            )
        }
        .appCardStyle(theme)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: viewModel.saveProfile) {
                HStack(spacing: 10) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(palette.onPrimary)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)
                    }

                    Text(viewModel.isSaving ? "Saving profile..." : "Save profile")
                        .font(.headline)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: theme))
            .disabled(!viewModel.canSubmit || viewModel.isSaving)
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Text("Public browsing is available without completing these optional fields.")
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
                .padding(.bottom, 6)
        }
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

private struct ProfileInputField: View {
    let theme: AppSectionTheme
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    var autocapitalization: TextInputAutocapitalization = .words
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(palette.textPrimary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .appTextFieldStyle(theme)
        }
    }
}
 
