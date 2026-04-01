//
//  ProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statsSection
                    optionsSection
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
            
            Text("Guest User")
                .font(.title2.bold())
            
            Text("Manage your information, bookings, and rewards.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemGray6))
        )
    }
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(title: "Points", value: "0")
            statCard(title: "Orders", value: "0")
            statCard(title: "Bookings", value: "0")
        }
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemGray6))
        )
    }
    
    private var optionsSection: some View {
        VStack(spacing: 12) {
            profileRow(title: "Personal Information", systemImage: "person.text.rectangle")
            profileRow(title: "Rewards & Points", systemImage: "gift")
            profileRow(title: "Payment Methods", systemImage: "creditcard")
            profileRow(title: "Settings", systemImage: "gearshape")
            profileRow(title: "Help & Support", systemImage: "questionmark.circle")
        }
    }
    
    private func profileRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .frame(width: 24)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}
