//
//  CompleteProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct CompleteProfileView: View {
    @StateObject private var viewModel: CompleteProfileViewModel

    init(viewModelFactory: @escaping () -> CompleteProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#141414"),
                    Color(hex: "#2A1A12"),
                    Color(hex: "#55341E")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    personalInfoSection
                    addressSection
                    emergencySection

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.95))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }

                    Text("This step is required before entering the app.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                }
                .padding(.top, 16)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 46))
                .foregroundStyle(.white)

            Text("Complete your profile")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("We need a few details before you can continue to Altos del Murco.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 24)
        }
        .padding(.top, 12)
    }

    private var personalInfoSection: some View {
        VStack(spacing: 14) {
            SectionTitle(title: "Personal information")

            BrandInputField(
                title: "Full name",
                placeholder: "Enter your full name",
                text: $viewModel.fullName,
                keyboardType: .default
            )

            BrandInputField(
                title: "National unique number",
                placeholder: "Example: 0501234567",
                text: $viewModel.nationalId,
                keyboardType: .numberPad
            )

            BrandInputField(
                title: "Phone number",
                placeholder: "Example: 0987654321",
                text: $viewModel.phoneNumber,
                keyboardType: .phonePad
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Birthday")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.95))

                DatePicker(
                    "",
                    selection: $viewModel.birthday,
                    in: viewModel.validBirthdayRange,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
    }

    private var addressSection: some View {
        VStack(spacing: 14) {
            SectionTitle(title: "Address")

            VStack(alignment: .leading, spacing: 8) {
                Text("Address")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.95))

                TextField("Street, reference, sector...", text: $viewModel.address, axis: .vertical)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(minHeight: 100, alignment: .topLeading)
                    .background(.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
    }

    private var emergencySection: some View {
        VStack(spacing: 14) {
            SectionTitle(title: "Emergency contact")

            BrandInputField(
                title: "Emergency contact name",
                placeholder: "Who should we contact if needed?",
                text: $viewModel.emergencyContactName,
                keyboardType: .default
            )

            BrandInputField(
                title: "Emergency contact phone",
                placeholder: "Example: 0999999999",
                text: $viewModel.emergencyContactPhone,
                keyboardType: .phonePad
            )
        }
        .padding(.horizontal, 20)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: viewModel.saveProfile) {
                HStack(spacing: 10) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)
                    }

                    Text(viewModel.isSaving ? "Saving profile..." : "Save and continue")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(PrimaryFilledButtonStyle())
            .disabled(!viewModel.canSubmit || viewModel.isSaving)
            .padding(.horizontal, 20)
            .padding(.top, 10)

            Text("You cannot skip this step.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 6)
        }
        .background(.ultraThinMaterial)
    }
}

private struct SectionTitle: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline.bold())
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

private struct BrandInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.95))

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .padding()
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
