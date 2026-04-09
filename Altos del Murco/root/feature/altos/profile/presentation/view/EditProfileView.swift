//
//  EditProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: EditProfileViewModel
    
    private let theme: AppSectionTheme = .neutral

    init(viewModelFactory: @escaping () -> EditProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }

    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ProfileFieldSection(theme: theme, title: "Account") {
                        ReadOnlyFieldCard(
                            theme: theme,
                            title: "Email",
                            value: viewModel.email.isEmpty ? "Hidden by Apple" : viewModel.email
                        )
                    }

                    ProfileFieldSection(theme: theme, title: "Personal information") {
                        EditableFieldCard(
                            theme: theme,
                            title: "Full name",
                            placeholder: "Enter your full name",
                            text: $viewModel.fullName,
                            keyboardType: .default
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "National unique number",
                            placeholder: "Example: 0501234567",
                            text: $viewModel.nationalId,
                            keyboardType: .numberPad
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Phone number",
                            placeholder: "Example: 0987654321",
                            text: $viewModel.phoneNumber,
                            keyboardType: .phonePad
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Birthday", systemImage: "calendar")
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.textPrimary)

                            DatePicker(
                                "Birthday",
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

                    ProfileFieldSection(theme: theme, title: "Address") {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Address", systemImage: "house")
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

                    ProfileFieldSection(theme: theme, title: "Emergency contact") {
                        EditableFieldCard(
                            theme: theme,
                            title: "Emergency contact name",
                            placeholder: "Who should we contact if needed?",
                            text: $viewModel.emergencyContactName,
                            keyboardType: .default
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Emergency contact phone",
                            placeholder: "Example: 0999999999",
                            text: $viewModel.emergencyContactPhone,
                            keyboardType: .phonePad
                        )
                    }

                    if let errorMessage = viewModel.errorMessage {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(palette.destructive)
                            
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(palette.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                .fill(palette.destructive.opacity(colorScheme == .dark ? 0.14 : 0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                .stroke(palette.destructive.opacity(0.25), lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.saveChanges()
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(palette.primary)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                }
            }
            .onChange(of: viewModel.isSaving) { _, isSaving in
                if !isSaving, viewModel.errorMessage == nil {
                    dismiss()
                }
            }
        }
        .appScreenStyle(theme)
    }
}

private struct ProfileFieldSection<Content: View>: View {
    let theme: AppSectionTheme
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(theme: theme, title: title)
            content
        }
        .appCardStyle(theme)
    }
}

private struct EditableFieldCard: View {
    let theme: AppSectionTheme
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboardType == .default ? .words : .never)
                .autocorrectionDisabled()
                .appTextFieldStyle(theme)
        }
    }
}

private struct ReadOnlyFieldCard: View {
    let theme: AppSectionTheme
    let title: String
    let value: String
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())

            Text(value)
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
                .foregroundStyle(palette.textSecondary)
        }
    }
}
