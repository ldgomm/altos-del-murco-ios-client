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
    
    @FocusState private var focusedField: ProfileField?

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
                            placeholder: "Opcional",
                            text: $viewModel.fullName,
                            keyboardType: .default,
                            focusedField: $focusedField,
                            field: .fullName
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Número de teléfono",
                            placeholder: "Opcional",
                            text: $viewModel.phoneNumber,
                            keyboardType: .phonePad,
                            focusedField: $focusedField,
                            field: .phoneNumber
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

                            TextField("Opcional", text: $viewModel.address, axis: .vertical)
                                .focused($focusedField, equals: .address)
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
                            placeholder: "Opcional",
                            text: $viewModel.emergencyContactName,
                            keyboardType: .default,
                            focusedField: $focusedField,
                            field: .emergencyContactName
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Teléfono del contacto de emergencia",
                            placeholder: "Opcional",
                            text: $viewModel.emergencyContactPhone,
                            keyboardType: .phonePad,
                            focusedField: $focusedField,
                            field: .emergencyContactPhone
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
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    focusedField = nil
                }
            )
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") {
                        focusedField = nil
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        focusedField = nil
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

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Listo") {
                        focusedField = nil
                    }
                    .fontWeight(.semibold)
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
    let focusedField: FocusState<ProfileField?>.Binding
    let field: ProfileField

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())

            TextField(placeholder, text: $text)
                .focused(focusedField, equals: field)
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

private enum ProfileField: Hashable {
    case fullName
    case phoneNumber
    case address
    case emergencyContactName
    case emergencyContactPhone
}
