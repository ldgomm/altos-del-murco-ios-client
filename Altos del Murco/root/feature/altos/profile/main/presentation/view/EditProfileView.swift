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
                    ProfileFieldSection(theme: theme, title: "Cuenta") {
                        ReadOnlyFieldCard(
                            theme: theme,
                            title: "Correo electrónico",
                            value: viewModel.email.isEmpty ? "Oculto por Apple" : viewModel.email
                        )
                    }

                    ProfileFieldSection(theme: theme, title: "Información personal") {
                        EditableFieldCard(
                            theme: theme,
                            title: "Nombre completo",
                            placeholder: "Ingresa tu nombre completo",
                            text: $viewModel.fullName,
                            keyboardType: .default
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Número de cédula",
                            placeholder: "Ejemplo: 0501234567",
                            text: $viewModel.nationalId,
                            keyboardType: .numberPad
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Número de teléfono",
                            placeholder: "Ejemplo: 0987654321",
                            text: $viewModel.phoneNumber,
                            keyboardType: .phonePad
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Fecha de nacimiento", systemImage: "calendar")
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.textPrimary)

                            DatePicker(
                                "Fecha de nacimiento",
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

                    ProfileFieldSection(theme: theme, title: "Dirección") {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Dirección", systemImage: "house")
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.textPrimary)

                            TextField("Calle, referencia, sector...", text: $viewModel.address, axis: .vertical)
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

                    ProfileFieldSection(theme: theme, title: "Contacto de emergencia") {
                        EditableFieldCard(
                            theme: theme,
                            title: "Nombre del contacto de emergencia",
                            placeholder: "¿A quién debemos contactar si es necesario?",
                            text: $viewModel.emergencyContactName,
                            keyboardType: .default
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Teléfono del contacto de emergencia",
                            placeholder: "Ejemplo: 0999999999",
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
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") {
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
                            Text("Guardar")
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
