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
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandScreenBackground(theme: .neutral)
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        consequencesCard
                        actionSection
                        
                        if viewModel.isDeletingAccount {
                            ProgressView("Eliminando cuenta...")
                                .tint(palette.destructive)
                                .foregroundStyle(palette.textSecondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Confirmar eliminación")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .tint(palette.primary)
    }
    
    private var headerSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(palette.destructive.opacity(colorScheme == .dark ? 0.20 : 0.12))
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .stroke(palette.destructive.opacity(0.25), lineWidth: 1)
                    )
                
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(palette.destructive)
            }
            
            VStack(spacing: 10) {
                Text("Eliminar cuenta")
                    .font(.title2.bold())
                    .foregroundStyle(palette.textPrimary)
                
                Text("Esta acción es permanente. Tu perfil será eliminado y perderás el acceso a tu cuenta.")
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    private var consequencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            warningRow(
                systemImage: "person.crop.circle.badge.xmark",
                text: "Tu perfil de cliente será eliminado"
            )
            
            warningRow(
                systemImage: "rectangle.portrait.and.arrow.right",
                text: "Se cerrará tu sesión inmediatamente"
            )
            
            warningRow(
                systemImage: "exclamationmark.triangle.fill",
                text: "Esta acción no se puede deshacer"
            )
        }
        .appCardStyle(.neutral, emphasized: true)
    }
    
    private var actionSection: some View {
        VStack(spacing: 14) {
            Text("Para continuar, confirma tu identidad con Apple.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
            
            SignInWithAppleButton(
                onRequest: viewModel.onDeleteRequest,
                onCompletion: viewModel.onDeleteCompletion
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.18 : 0.08),
                radius: 12,
                x: 0,
                y: 6
            )
        }
    }
    
    private func warningRow(systemImage: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(palette.destructive.opacity(colorScheme == .dark ? 0.18 : 0.10))
                    .frame(width: 36, height: 36)
                
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.destructive)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(palette.textPrimary)
            
            Spacer()
        }
    }
}
