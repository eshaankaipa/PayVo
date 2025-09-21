//
//  ContactsView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    @State private var animateElements = false
    @State private var showAddContact = false
    @State private var searchText = ""
    @State private var contactToDelete: Contact?
    @State private var showDeleteAlert = false
    
    var contacts: [Contact] {
        return userDatabase.getContacts()
    }
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts.sorted { $0.name < $1.name }
        } else {
            return contacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Professional finance background
                LinearGradient(
                    gradient: Gradient(colors: [
                        FinanceColors.backgroundPrimary,
                        FinanceColors.backgroundSecondary
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 20) {
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(FinanceColors.textPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(FinanceColors.cardBackground)
                                            .financeCardStyle()
                                    )
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text("Contacts")
                                    .font(FinanceFonts.heading2)
                                    .foregroundColor(FinanceColors.textPrimary)
                                
                                Text("\(contacts.count) contacts")
                                    .font(FinanceFonts.bodySmall)
                                    .foregroundColor(FinanceColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showAddContact = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(FinanceColors.primaryBlue)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(FinanceColors.cardBackground)
                                            .financeCardStyle()
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateElements)
                    
                    // Search bar
                    if !contacts.isEmpty {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(FinanceColors.textSecondary)
                                .padding(.leading, 16)
                            
                            TextField("Search contacts...", text: $searchText)
                                .font(FinanceFonts.bodyMedium)
                                .padding(.vertical, 12)
                                .padding(.trailing, 16)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: FinanceRadius.md)
                                .fill(FinanceColors.cardBackground)
                                .financeCardStyle()
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : -10)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
                    }
                    
                    // Contacts list
                    if filteredContacts.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 60))
                                .foregroundColor(FinanceColors.textTertiary)
                            
                            VStack(spacing: 8) {
                                Text(contacts.isEmpty ? "No Contacts" : "No Results")
                                    .font(FinanceFonts.heading3)
                                    .foregroundColor(FinanceColors.textPrimary)
                                
                                Text(contacts.isEmpty ? "Add contacts to send money" : "Try a different search term")
                                    .font(FinanceFonts.bodyMedium)
                                    .foregroundColor(FinanceColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            if contacts.isEmpty {
                                Button(action: {
                                    showAddContact = true
                                }) {
                                    Text("Add First Contact")
                                        .font(FinanceFonts.button)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: FinanceRadius.md)
                                                .fill(FinanceColors.primaryBlue)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 60)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
                    } else {
                        // Contacts list
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(filteredContacts.enumerated()), id: \.element.id) { index, contact in
                                    ContactRow(contact: contact, onTransfer: {
                                        // Transfer money action
                                        transferMoney(to: contact)
                                    }, onDelete: {
                                        // Delete contact action
                                        contactToDelete = contact
                                        showDeleteAlert = true
                                    })
                                    .opacity(animateElements ? 1.0 : 0.0)
                                    .offset(x: animateElements ? 0 : -20)
                                    .animation(.easeOut(duration: 0.4).delay(0.4 + Double(index) * 0.05), value: animateElements)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            animateElements = true
            loadContacts()
        }
        .sheet(isPresented: $showAddContact) {
            AddContactView { newContact in
                userDatabase.addContact(newContact)
            }
            .environmentObject(userDatabase)
        }
        .alert("Delete Contact", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let contact = contactToDelete {
                    deleteContact(contact)
                }
            }
        } message: {
            if let contact = contactToDelete {
                Text("Are you sure you want to delete \(contact.name)? This action cannot be undone.")
            }
        }
    }
    
    private func loadContacts() {
        // Contacts are now loaded automatically from UserDatabase
        // This method is kept for compatibility but doesn't need to do anything
    }
    
    private func transferMoney(to contact: Contact) {
        // Transfer money functionality - could open a transfer sheet or navigate to money options
        print("Transfer money to \(contact.name)")
        // For now, just print - could be enhanced to open transfer interface
    }
    
    private func deleteContact(_ contact: Contact) {
        print("🗑️ Deleting contact: \(contact.name)")
        userDatabase.deleteContact(contact)
        contactToDelete = nil
    }
}

struct ContactRow: View {
    let contact: Contact
    let onTransfer: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(FinanceColors.accentBlue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(String(contact.name.prefix(1)))
                    .font(FinanceFonts.bodyLarge.weight(.semibold))
                    .foregroundColor(FinanceColors.accentBlue)
            }
            
            // Contact info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(FinanceFonts.bodyMedium.weight(.semibold))
                    .foregroundColor(FinanceColors.textPrimary)
                
                Text("Balance: $\(String(format: "%.2f", contact.balance))")
                    .font(FinanceFonts.caption)
                    .foregroundColor(FinanceColors.successGreen)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onTransfer) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(FinanceColors.successGreen)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FinanceColors.errorRed)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: FinanceRadius.md)
                .fill(FinanceColors.cardBackground)
                .financeCardStyle()
        )
    }
}

struct AddContactView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userDatabase: UserDatabase
    let onSave: (Contact) -> Void
    
    @State private var searchQuery = ""
    @State private var searchResults: [UserAccount] = []
    @State private var selectedUser: UserAccount?
    @State private var showSearchResults = false
    @State private var errorMessage = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Add Contact")
                        .font(FinanceFonts.heading2)
                        .foregroundColor(FinanceColors.textPrimary)
                    
                    Text("Search for existing users to add as contacts")
                        .font(FinanceFonts.bodyMedium)
                        .foregroundColor(FinanceColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)
                
                // Search section
                VStack(spacing: 16) {
                    // Search input
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(FinanceColors.textSecondary)
                            .padding(.leading, 16)
                        
                        TextField("Search by name or email...", text: $searchQuery)
                            .font(FinanceFonts.bodyMedium)
                            .padding(.vertical, 12)
                            .padding(.trailing, 16)
                            .onChange(of: searchQuery) { query in
                                performSearch(query: query)
                            }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                            .fill(FinanceColors.cardBackground)
                            .financeCardStyle()
                    )
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(FinanceFonts.bodySmall)
                            .foregroundColor(FinanceColors.errorRed)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Search results
                    if showSearchResults {
                        if searchResults.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(FinanceColors.textTertiary)
                                
                                Text("No users found")
                                    .font(FinanceFonts.bodyMedium)
                                    .foregroundColor(FinanceColors.textSecondary)
                                
                                Text("Try searching with a different name or email")
                                    .font(FinanceFonts.bodySmall)
                                    .foregroundColor(FinanceColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(searchResults, id: \.email) { user in
                                        UserSearchResultRow(user: user) {
                                            selectedUser = user
                                            showSearchResults = false
                                            errorMessage = ""
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 300)
                        }
                    }
                    
                    // Selected user preview
                    if let selectedUser = selectedUser {
                        VStack(spacing: 12) {
                            Text("Selected User")
                                .font(FinanceFonts.label)
                                .foregroundColor(FinanceColors.textSecondary)
                            
                            HStack(spacing: 16) {
                                // Avatar
                                ZStack {
                                    Circle()
                                        .fill(FinanceColors.primaryBlue.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    
                                    Text(String(selectedUser.name.prefix(1)))
                                        .font(FinanceFonts.bodyLarge.weight(.semibold))
                                        .foregroundColor(FinanceColors.primaryBlue)
                                }
                                
                                // User info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedUser.name)
                                        .font(FinanceFonts.bodyMedium.weight(.semibold))
                                        .foregroundColor(FinanceColors.textPrimary)
                                    
                                    Text(selectedUser.email)
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(FinanceColors.textSecondary)
                                    
                                    Text("Member since \(formatDate(selectedUser.dateCreated))")
                                        .font(FinanceFonts.caption)
                                        .foregroundColor(FinanceColors.textTertiary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    self.selectedUser = nil
                                    searchQuery = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(FinanceColors.textSecondary)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.md)
                                    .fill(FinanceColors.cardBackground)
                                    .financeCardStyle()
                            )
                            
                            // Add contact button
                            Button(action: addSelectedUserAsContact) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Add as Contact")
                                        .font(FinanceFonts.button)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: FinanceRadius.button)
                                        .fill(FinanceColors.primaryBlue)
                                )
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func performSearch(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedQuery.isEmpty {
            searchResults = []
            showSearchResults = false
            return
        }
        
        // Debounce search to avoid too many calls
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedQuery {
                self.searchResults = self.userDatabase.searchExistingUsers(query: trimmedQuery)
                self.showSearchResults = true
                self.errorMessage = ""
            }
        }
    }
    
    private func addSelectedUserAsContact() {
        guard let user = selectedUser else { return }
        
        // Create contact from user account
        let newContact = Contact(
            name: user.name,
            balance: user.balance, // Use the user's actual balance
            phoneNumber: user.phoneNumber,
            email: user.email
        )
        
        print("💾 Adding existing user as contact: \(user.name) with balance: $\(user.balance)")
        
        onSave(newContact)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct UserSearchResultRow: View {
    let user: UserAccount
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(FinanceColors.primaryBlue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text(String(user.name.prefix(1)))
                        .font(FinanceFonts.bodyMedium.weight(.semibold))
                        .foregroundColor(FinanceColors.primaryBlue)
                }
                
                // User info
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(FinanceFonts.bodyMedium.weight(.medium))
                        .foregroundColor(FinanceColors.textPrimary)
                    
                    Text(user.email)
                        .font(FinanceFonts.caption)
                        .foregroundColor(FinanceColors.textSecondary)
                }
                
                Spacer()
                
                // Select indicator
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(FinanceColors.primaryBlue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(FinanceColors.backgroundSecondary)
            )
        }
    }
}

struct FinanceTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(FinanceFonts.bodyMedium)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: FinanceRadius.md)
                    .fill(FinanceColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                            .stroke(FinanceColors.primaryBlue, lineWidth: 1)
                    )
            )
    }
}

#Preview {
    ContactsView()
        .environmentObject(UserDatabase())
}
