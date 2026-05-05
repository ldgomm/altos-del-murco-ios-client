//
//  QuickContactProfileSheet.swift
//  Altos del Murco
//
//  Created by José Ruiz on 5/5/26.
//

import SwiftUI

struct QuickContactProfileSheet: View {
    let theme: AppSectionTheme
    let title: String
    let message: String
    let initialName: String
    let initialPhone: String
    let saveProfile: (String, String) async throws -> ClientProfile
    let onSaved: (ClientProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var fullName: String
    @State private var phoneNumber: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        theme: AppSectionTheme,
        title: String,
        message: String,
        initialName: String,
        initialPhone: String,
        saveProfile: @escaping (String, String) async throws -> ClientProfile,
        onSaved: @escaping (ClientProfile) -> Void
    ) {
        self.theme = theme
        self.title = title
        self.message = message
        self.initialName = initialName
        self.initialPhone = initialPhone
        self.saveProfile = saveProfile
        self.onSaved = onSaved
        _fullName = State(initialValue: initialName)
        _phoneNumber = State(initialValue: initialPhone)
    }

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    private var nameIsMissing: Bool {
        fullName.trimmed.isEmpty
    }

    private var phoneIsMissing: Bool {
        phoneNumber.digitsOnly.isEmpty
    }

    private var phoneIsInvalid: Bool {
        !phoneNumber.digitsOnly.isEmpty && phoneNumber.digitsOnly.count < 8
    }

    private var canSave: Bool {
        !nameIsMissing && !phoneIsMissing && !phoneIsInvalid && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard

                    VStack(spacing: 14) {
                        TextField(
                            "",
                            text: $fullName,
                            prompt: Text("Nombre completo")
                        )
                        .textInputAutocapitalization(.words)
                        .appTextFieldStyle(theme)

                        TextField(
                            "",
                            text: $phoneNumber,
                            prompt: Text("WhatsApp")
                        )
                        .keyboardType(.phonePad)
                        .appTextFieldStyle(theme)
                    }

                    statusCard

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(palette.destructive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appCardStyle(theme, emphasized: false)
                    }

                    Button {
                        save()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(palette.onPrimary)
                            } else {
                                Image(systemName: "checkmark.seal.fill")
                            }

                            Text(isSaving ? "Guardando..." : "Guardar y continuar")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrandPrimaryButtonStyle(theme: theme))
                    .disabled(!canSave)

                    Button("Ahora no") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .navigationTitle("Contacto")
            .navigationBarTitleDisplayMode(.inline)
            .appScreenStyle(theme)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandIconBubble(
                theme: theme,
                systemImage: "person.crop.circle.badge.checkmark",
                size: 52
            )

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(palette.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCardStyle(theme)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            profileRequirementRow(
                completed: !nameIsMissing,
                title: nameIsMissing ? "Falta el nombre" : "Nombre listo",
                message: nameIsMissing
                    ? "Lo usamos para identificar tu pedido o reserva."
                    : fullName.trimmed
            )

            profileRequirementRow(
                completed: !phoneIsMissing && !phoneIsInvalid,
                title: phoneIsMissing ? "Falta WhatsApp" : phoneIsInvalid ? "WhatsApp incompleto" : "WhatsApp listo",
                message: phoneIsMissing
                    ? "Nos ayuda a confirmar cambios, horarios o disponibilidad."
                    : phoneIsInvalid
                        ? "Revisa que tenga al menos 8 dígitos."
                        : phoneNumber.digitsOnly
            )
        }
        .appCardStyle(theme, emphasized: false)
    }

    private func profileRequirementRow(
        completed: Bool,
        title: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: completed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundStyle(completed ? palette.success : palette.destructive)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()
        }
    }

    private func save() {
        guard canSave else { return }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                let profile = try await saveProfile(fullName, phoneNumber)
                await MainActor.run {
                    isSaving = false
                    onSaved(profile)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
