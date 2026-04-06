//
//  EditProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditProfileViewModel

    init(viewModelFactory: @escaping () -> EditProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ProfileFieldSection(title: "Account") {
                        ReadOnlyFieldCard(
                            title: "Email",
                            value: viewModel.email.isEmpty ? "Hidden by Apple" : viewModel.email
                        )
                    }

                    ProfileFieldSection(title: "Personal information") {
                        EditableFieldCard(
                            title: "Full name",
                            placeholder: "Enter your full name",
                            text: $viewModel.fullName,
                            keyboardType: .default
                        )

                        EditableFieldCard(
                            title: "National unique number",
                            placeholder: "Example: 0501234567",
                            text: $viewModel.nationalId,
                            keyboardType: .numberPad
                        )

                        EditableFieldCard(
                            title: "Phone number",
                            placeholder: "Example: 0987654321",
                            text: $viewModel.phoneNumber,
                            keyboardType: .phonePad
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Birthday")
                                .font(.subheadline.bold())

                            DatePicker(
                                "",
                                selection: $viewModel.birthday,
                                in: viewModel.validBirthdayRange,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                    }

                    ProfileFieldSection(title: "Address") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Address")
                                .font(.subheadline.bold())

                            TextField("Street, reference, sector...", text: $viewModel.address, axis: .vertical)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .frame(minHeight: 100, alignment: .topLeading)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }
                    }

                    ProfileFieldSection(title: "Emergency contact") {
                        EditableFieldCard(
                            title: "Emergency contact name",
                            placeholder: "Who should we contact if needed?",
                            text: $viewModel.emergencyContactName,
                            keyboardType: .default
                        )

                        EditableFieldCard(
                            title: "Emergency contact phone",
                            placeholder: "Example: 0999999999",
                            text: $viewModel.emergencyContactPhone,
                            keyboardType: .phonePad
                        )
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
    }
}

private struct ProfileFieldSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline.bold())

            content
        }
    }
}

private struct EditableFieldCard: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }
}

private struct ReadOnlyFieldCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())

            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
                )
                .foregroundStyle(.secondary)
        }
    }
}
