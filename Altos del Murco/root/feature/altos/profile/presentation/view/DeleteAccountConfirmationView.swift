//
//  DeleteAccountConfirmationView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI
import AuthenticationServices

struct DeleteAccountConfirmationView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.red)

                Text("Delete account")
                    .font(.title2.bold())

                Text("This action is permanent. Your profile will be removed and you will lose access to your account.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Your client profile will be deleted", systemImage: "person.crop.circle.badge.xmark")
                    Label("You will be signed out immediately", systemImage: "rectangle.portrait.and.arrow.right")
                    Label("This action cannot be undone", systemImage: "exclamationmark.triangle.fill")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                )

                SignInWithAppleButton(
                    onRequest: viewModel.onDeleteRequest,
                    onCompletion: viewModel.onDeleteCompletion
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 54)
                .clipShape(Capsule())
                .padding(.top, 8)

                if viewModel.isDeletingAccount {
                    ProgressView("Deleting account...")
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Confirm Deletion")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
