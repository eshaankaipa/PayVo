//
//  UserDatabase.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import Foundation
import Combine
import UIKit

struct UserAccount: Codable {
    let email: String
    var name: String
    let phoneNumber: String
    let voicePassword: String
    let voiceSample: VoiceSample?
    let dateCreated: Date
    var balance: Double
    var transactionHistory: [Transaction]
    var contacts: [Contact]
    let uniqueTag: String
    
    init(email: String, name: String, phoneNumber: String, voicePassword: String, voiceSample: VoiceSample? = nil, dateCreated: Date = Date(), balance: Double = 1250.0) {
        self.email = email
        self.name = name
        self.phoneNumber = phoneNumber
        self.voicePassword = voicePassword
        self.voiceSample = voiceSample
        self.dateCreated = dateCreated
        self.balance = balance
        self.transactionHistory = []
        self.contacts = []
        self.uniqueTag = UserAccount.generateUniqueTag()
    }
    
    static func generateUniqueTag() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let tagLength = 6
        var result = ""
        for _ in 0..<tagLength {
            let randomIndex = Int.random(in: 0..<letters.count)
            let character = letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
            result.append(character)
        }
        return result
    }
}

struct Transaction: Codable, Identifiable {
    let id = UUID()
    let type: TransactionType
    let amount: Double
    let timestamp: Date
    let description: String
    let recipientName: String?
    let senderName: String?
    
    init(type: TransactionType, amount: Double, timestamp: Date = Date(), description: String, recipientName: String? = nil, senderName: String? = nil) {
        self.type = type
        self.amount = amount
        self.timestamp = timestamp
        self.description = description
        self.recipientName = recipientName
        self.senderName = senderName
    }
    
    enum TransactionType: String, Codable {
        case withdrawal = "withdrawal"
        case deposit = "deposit"
        case transfer = "transfer"
        case split = "split"
        case request = "request"
        case send = "send"
    }
}

struct Contact: Codable, Identifiable, Hashable {
    let id = UUID()
    var name: String
    var balance: Double
    var phoneNumber: String?
    var email: String?
    
    init(name: String, balance: Double = 0.0, phoneNumber: String? = nil, email: String? = nil) {
        self.name = name
        self.balance = balance
        self.phoneNumber = phoneNumber
        self.email = email
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PendingRequest: Codable, Identifiable {
    let id = UUID()
    let fromUserEmail: String
    let fromUserName: String
    let toUserEmail: String
    let toUserName: String
    let amount: Double
    let description: String
    let dateCreated: Date
    var status: RequestStatus
    
    init(fromUserEmail: String, fromUserName: String, toUserEmail: String, toUserName: String, amount: Double, description: String) {
        self.fromUserEmail = fromUserEmail
        self.fromUserName = fromUserName
        self.toUserEmail = toUserEmail
        self.toUserName = toUserName
        self.amount = amount
        self.description = description
        self.dateCreated = Date()
        self.status = .pending
    }
}

enum RequestStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
}

class UserDatabase: ObservableObject {
    @Published var currentUser: UserAccount?
    @Published var allAccounts: [UserAccount] = []
    @Published var pendingRequests: [PendingRequest] = []
    private let userDefaults = UserDefaults.standard
    private let userKey = "saved_user_account"
    private let accountsKey = "saved_user_accounts"
    private let pendingRequestsKey = "saved_pending_requests"
    
    // File-based persistence paths
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    private var userFileURL: URL {
        documentsDirectory.appendingPathComponent("current_user.json")
    }
    private var accountsFileURL: URL {
        documentsDirectory.appendingPathComponent("all_accounts.json")
    }
    private var pendingRequestsFileURL: URL {
        documentsDirectory.appendingPathComponent("pending_requests.json")
    }
    
    init() {
        print("🏗️ UserDatabase initializing...")
        print("📁 Documents directory: \(documentsDirectory.path)")
        print("📄 User file path: \(userFileURL.path)")
        print("📄 Accounts file path: \(accountsFileURL.path)")
        
        // Check if this is a rebuild (app was killed without proper cleanup)
        let wasProperlyClosed = userDefaults.bool(forKey: "app_properly_closed")
        let hasExistingData = FileManager.default.fileExists(atPath: userFileURL.path) || 
                             FileManager.default.fileExists(atPath: accountsFileURL.path)
        
        if !wasProperlyClosed && hasExistingData {
            // This is a rebuild - clear all data
            print("🔄 Xcode rebuild detected - clearing all accounts and data")
            clearAllData()
        } else if wasProperlyClosed {
            // Normal app start - load existing data
            print("📱 Normal app start - loading existing data")
            loadUser()
            loadAllAccounts()
            loadPendingRequests()
        } else {
            // First time app launch - no data to load
            print("🆕 First time app launch - no existing data")
        }
        
        // Set flag to indicate app is running properly
        userDefaults.set(true, forKey: "app_properly_closed")
        
        // Set up app lifecycle notifications
        setupAppLifecycleNotifications()
        
        print("✅ UserDatabase initialization complete")
    }
    
    deinit {
        // Clear the flag when app is properly closed
        userDefaults.set(false, forKey: "app_properly_closed")
        print("🔚 UserDatabase deinitialized - app properly closed")
    }
    
    private func setupAppLifecycleNotifications() {
        // Listen for app termination
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Save all data before termination
            self.saveUser()
            self.saveAllAccounts()
            self.userDefaults.set(false, forKey: "app_properly_closed")
            print("🔚 App will terminate - data saved and flag cleared")
        }
        
        // Listen for app going to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Save data when going to background
            self.saveUser()
            self.saveAllAccounts()
            print("💾 App entering background - data saved")
        }
        
        // Listen for app becoming inactive (user switches apps, etc.)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Save data when app becomes inactive
            self.saveUser()
            self.saveAllAccounts()
            print("💾 Data saved when app becomes inactive")
        }
    }
    
    func hasUser() -> Bool {
        return currentUser != nil
    }
    
    func createUser(email: String, name: String, phoneNumber: String, voicePassword: String, voiceSample: VoiceSample? = nil) {
        print("🏗️ UserDatabase.createUser called with:")
        print("  📧 Email: \(email)")
        print("  👤 Name: \(name)")
        print("  📱 Phone: \(phoneNumber)")
        
        let newUser = UserAccount(
            email: email,
            name: name,
            phoneNumber: phoneNumber,
            voicePassword: voicePassword,
            voiceSample: voiceSample,
            dateCreated: Date(),
            balance: generateRandomBalance()
        )
        
        print("💰 Generated random balance: $\(String(format: "%.2f", newUser.balance))")
        print("🏷️ Generated unique tag: \(newUser.uniqueTag)")
        
        currentUser = newUser
        addAccount(newUser)
        saveUser()
        
        print("📝 Account saved to database")
        
        // Automatically initialize contacts for new users
        print("👥 Initializing contacts with random balances...")
        initializeContactsWithRandomBalances()
        
        // Ensure user information is properly populated
        populateUserInformation()
        
        print("✅ Account creation complete!")
    }
    
    // MARK: - User Information Population
    
    func populateUserInformation() {
        guard let user = currentUser else {
            print("❌ No current user to populate information for")
            return
        }
        
        print("👤 UserDatabase - Populating user information:")
        print("  📧 Email: '\(user.email)'")
        print("  👤 Name: '\(user.name)'")
        print("  📱 Phone: '\(user.phoneNumber)'")
        print("  💰 Balance: $\(String(format: "%.2f", user.balance))")
        print("  🏷️ TAG: '\(user.uniqueTag)'")
        print("  📅 Created: \(user.dateCreated)")
        print("  👥 Contacts: \(user.contacts.count)")
        
        // Force UI update by triggering a save
        saveUser()
        
        print("✅ UserDatabase - User information populated and saved")
    }
    
    private func loadAllAccounts() {
        // Try to load from file first (survives Xcode rebuilds)
        if let fileData = try? Data(contentsOf: accountsFileURL),
           let fileAccounts = try? JSONDecoder().decode([UserAccount].self, from: fileData) {
            allAccounts = fileAccounts
            print("📁 Loaded accounts from file: \(fileAccounts.count) accounts")
            // Also save to UserDefaults as backup
            if let encoded = try? JSONEncoder().encode(allAccounts) {
                userDefaults.set(encoded, forKey: accountsKey)
            }
        } else if let data = userDefaults.data(forKey: accountsKey),
                  let accounts = try? JSONDecoder().decode([UserAccount].self, from: data) {
            allAccounts = accounts
            print("💾 Loaded accounts from UserDefaults: \(accounts.count) accounts")
            // Save to file for future persistence
            saveAllAccountsToFile()
        }
    }
    
    private func loadPendingRequests() {
        // Try to load from file first (survives Xcode rebuilds)
        if let fileData = try? Data(contentsOf: pendingRequestsFileURL),
           let fileRequests = try? JSONDecoder().decode([PendingRequest].self, from: fileData) {
            pendingRequests = fileRequests
            print("📁 Loaded pending requests from file: \(fileRequests.count) requests")
            // Also save to UserDefaults as backup
            if let encoded = try? JSONEncoder().encode(pendingRequests) {
                userDefaults.set(encoded, forKey: pendingRequestsKey)
            }
        } else if let data = userDefaults.data(forKey: pendingRequestsKey),
                  let requests = try? JSONDecoder().decode([PendingRequest].self, from: data) {
            pendingRequests = requests
            print("💾 Loaded pending requests from UserDefaults: \(requests.count) requests")
            // Save to file for future persistence
            savePendingRequestsToFile()
        }
    }
    
    private func saveAllAccounts() {
        // Save to both UserDefaults and file for maximum persistence
        if let encoded = try? JSONEncoder().encode(allAccounts) {
            userDefaults.set(encoded, forKey: accountsKey)
            saveAllAccountsToFile()
            print("💾 Saved \(allAccounts.count) accounts to both UserDefaults and file")
        }
    }
    
    private func saveAllAccountsToFile() {
        do {
            let encoded = try JSONEncoder().encode(allAccounts)
            try encoded.write(to: accountsFileURL)
            print("📁 Saved accounts to file: \(accountsFileURL.path)")
        } catch {
            print("❌ Failed to save accounts to file: \(error)")
        }
    }
    
    private func savePendingRequestsToFile() {
        do {
            let encoded = try JSONEncoder().encode(pendingRequests)
            try encoded.write(to: pendingRequestsFileURL)
            print("📁 Saved pending requests to file: \(pendingRequestsFileURL.path)")
        } catch {
            print("❌ Failed to save pending requests to file: \(error)")
        }
    }
    
    private func addAccount(_ account: UserAccount) {
        // Remove existing account with same email if it exists
        allAccounts.removeAll { $0.email == account.email }
        allAccounts.append(account)
        saveAllAccounts()
    }
    
    func deleteUser() {
        currentUser = nil
        allAccounts = []
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: accountsKey)
        // Also remove the files
        try? FileManager.default.removeItem(at: userFileURL)
        try? FileManager.default.removeItem(at: accountsFileURL)
        print("🗑️ Deleted current user and all accounts from UserDefaults and files")
    }
    
    func clearAllData() {
        // Clear current user
        currentUser = nil
        userDefaults.removeObject(forKey: userKey)
        try? FileManager.default.removeItem(at: userFileURL)
        
        // Clear all accounts
        allAccounts = []
        userDefaults.removeObject(forKey: accountsKey)
        try? FileManager.default.removeItem(at: accountsFileURL)
        
        // Clear pending requests
        pendingRequests = []
        userDefaults.removeObject(forKey: pendingRequestsKey)
        try? FileManager.default.removeItem(at: pendingRequestsFileURL)
        
        print("🧹 Cleared all user data from UserDefaults and files")
    }
    
    private func saveUser() {
        if let user = currentUser {
            // Save to both UserDefaults and file for maximum persistence
            if let encoded = try? JSONEncoder().encode(user) {
                userDefaults.set(encoded, forKey: userKey)
                saveUserToFile(user: user, encoded: encoded)
                print("💾 Saved current user to both UserDefaults and file")
            }
        }
    }
    
    private func saveUserToFile(user: UserAccount, encoded: Data) {
        do {
            try encoded.write(to: userFileURL)
            print("📁 Saved current user to file: \(userFileURL.path)")
        } catch {
            print("❌ Failed to save current user to file: \(error)")
        }
    }
    
    private func loadUser() {
        // Try to load from file first (survives Xcode rebuilds)
        if let fileData = try? Data(contentsOf: userFileURL),
           let fileUser = try? JSONDecoder().decode(UserAccount.self, from: fileData) {
            currentUser = fileUser
            print("📁 Loaded current user from file: \(fileUser.name)")
            // Also save to UserDefaults as backup
            if let encoded = try? JSONEncoder().encode(currentUser) {
                userDefaults.set(encoded, forKey: userKey)
            }
        } else if let data = userDefaults.data(forKey: userKey),
                  let user = try? JSONDecoder().decode(UserAccount.self, from: data) {
            currentUser = user
            print("💾 Loaded current user from UserDefaults: \(user.name)")
            // Save to file for future persistence
            if let encoded = try? JSONEncoder().encode(currentUser) {
                saveUserToFile(user: user, encoded: encoded)
            }
        }
    }
    
    func verifyVoicePassword(_ input: String) -> Bool {
        guard let user = currentUser else { return false }
        return input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == 
               user.voicePassword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func verifyVoiceBiometric(_ inputSample: VoiceSample) -> Bool {
        guard let user = currentUser, let storedSample = user.voiceSample else { return false }
        
        // Use the Web Speech API's stricter biometric comparison
        let webSpeechManager = WebSpeechAuthManager()
        return webSpeechManager.compareVoiceSamples(storedSample, inputSample)
    }
    
    func getVoiceMatchConfidence(_ inputSample: VoiceSample) -> Double {
        guard let user = currentUser, let storedSample = user.voiceSample else { return 0.0 }
        
        // Use the Web Speech API's stricter confidence calculation
        let webSpeechManager = WebSpeechAuthManager()
        return webSpeechManager.getVoiceMatchConfidence(storedSample, inputSample)
    }
    
    // MARK: - Login Authentication
    
    func authenticateLogin(voicePassword: String, voiceSample: VoiceSample) -> Bool {
        print("🔐 Login Authentication: Checking against \(allAccounts.count) accounts")
        
        // Normalize the input password
        let normalizedInputPassword = voicePassword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check each account in the database
        for account in allAccounts {
            print("🔍 Checking account: \(account.email)")
            
            // Check if voice password text matches
            let normalizedStoredPassword = account.voicePassword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let passwordMatch = normalizedStoredPassword == normalizedInputPassword
            
            print("  📝 Password check: '\(normalizedInputPassword)' vs '\(normalizedStoredPassword)' = \(passwordMatch)")
            
            if passwordMatch {
                // Password matches - log user into this account (text-based authentication only)
                print("✅ Authentication successful for account: \(account.email)")
                print("  📝 Password match: '\(normalizedInputPassword)' == '\(normalizedStoredPassword)'")
                
                // Ensure user has a balance (for existing users who might not have one)
                var updatedAccount = account
                if updatedAccount.balance <= 0 {
                    updatedAccount.balance = generateRandomBalance()
                    print("💰 Assigned random balance to existing user: $\(String(format: "%.2f", updatedAccount.balance))")
                }
                
                currentUser = updatedAccount
                updateAccountInList(updatedAccount)
                saveUser()
                return true
            }
        }
        
        print("❌ Authentication failed: No matching account found")
        return false
    }
    
    // MARK: - Balance Management
    
    func getCurrentBalance() -> Double {
        return currentUser?.balance ?? 0.0
    }
    
    func canWithdraw(amount: Double) -> Bool {
        guard let user = currentUser else { return false }
        return user.balance >= amount && amount > 0
    }
    
    func withdraw(amount: Double, description: String = "Withdrawal") -> Bool {
        print("💸 Withdraw called: amount=\(amount), description=\(description)")
        guard let user = currentUser else { 
            print("❌ Withdraw failed: no current user")
            return false 
        }
        guard canWithdraw(amount: amount) else { 
            print("❌ Withdraw failed: cannot withdraw amount=\(amount), balance=\(user.balance)")
            return false 
        }
        
        print("💰 Current balance before withdrawal: \(user.balance)")
        
        // Create updated user with new balance and transaction
        let transaction = Transaction(
            type: .withdrawal,
            amount: amount,
            timestamp: Date(),
            description: description
        )
        
        var updatedUser = user
        updatedUser.balance -= amount
        updatedUser.transactionHistory.append(transaction)
        
        print("💰 New balance after withdrawal: \(updatedUser.balance)")
        
        currentUser = updatedUser
        updateAccountInList(updatedUser)
        saveUser()
        
        print("✅ Withdrawal completed successfully")
        return true
    }
    
    func deposit(amount: Double, description: String = "Deposit") -> Bool {
        print("💳 Deposit called: amount=\(amount), description=\(description)")
        guard let user = currentUser, amount > 0 else { 
            print("❌ Deposit failed: user=\(currentUser != nil), amount=\(amount)")
            return false 
        }
        
        print("💰 Current balance before deposit: \(user.balance)")
        
        let transaction = Transaction(
            type: .deposit,
            amount: amount,
            timestamp: Date(),
            description: description
        )
        
        var updatedUser = user
        updatedUser.balance += amount
        updatedUser.transactionHistory.append(transaction)
        
        print("💰 New balance after deposit: \(updatedUser.balance)")
        
        currentUser = updatedUser
        updateAccountInList(updatedUser)
        saveUser()
        
        print("✅ Deposit completed successfully")
        return true
    }
    
    private func updateAccountInList(_ updatedUser: UserAccount) {
        if let index = allAccounts.firstIndex(where: { $0.email == updatedUser.email }) {
            allAccounts[index] = updatedUser
            saveAllAccounts()
        }
    }
    
    func getTransactionHistory() -> [Transaction] {
        return currentUser?.transactionHistory ?? []
    }
    
    // MARK: - Contact Management
    
    func getContacts() -> [Contact] {
        guard let user = currentUser else { return [] }
        
        // Sync contact balances with database users
        var updatedContacts = user.contacts.map { contact in
            var updatedContact = contact
            
            // If this contact has an email, check if it matches a database user
            if let contactEmail = contact.email,
               let databaseUser = findExistingUser(byEmail: contactEmail) {
                // Update the balance to match the database user's current balance
                updatedContact.balance = databaseUser.balance
                print("🔄 Synced contact balance: \(contact.name) now has $\(databaseUser.balance)")
            }
            
            return updatedContact
        }
        
        // Update the current user's contacts with synced balances
        if updatedContacts != user.contacts {
            currentUser?.contacts = updatedContacts
            saveUser()
        }
        
        return updatedContacts
    }
    
    // Helper method to update database user balances when they're involved in transactions
    private func updateDatabaseUserBalance(email: String, amountChange: Double, transactionType: Transaction.TransactionType, description: String, fromUserName: String) -> Bool {
        guard let userIndex = allAccounts.firstIndex(where: { $0.email.lowercased() == email.lowercased() }) else {
            print("❌ Database user not found for email: \(email)")
            return false
        }
        
        // Check if user has sufficient balance for negative changes
        if amountChange < 0 && allAccounts[userIndex].balance < abs(amountChange) {
            print("❌ Database user has insufficient balance: \(allAccounts[userIndex].balance) < \(abs(amountChange))")
            return false
        }
        
        // Update balance
        allAccounts[userIndex].balance += amountChange
        
        // Add transaction to their history
        let transaction = Transaction(
            type: transactionType,
            amount: amountChange,
            timestamp: Date(),
            description: description,
            recipientName: amountChange > 0 ? nil : fromUserName,
            senderName: amountChange > 0 ? fromUserName : nil
        )
        allAccounts[userIndex].transactionHistory.append(transaction)
        
        print("✅ Updated database user balance: \(allAccounts[userIndex].name) now has $\(allAccounts[userIndex].balance)")
        
        // Save the updated account data
        saveAllAccountsToFile()
        
        return true
    }
    
    func addContact(_ contact: Contact) {
        guard var user = currentUser else { return }
        user.contacts.append(contact)
        
        // Update @Published properties on main thread with immediate execution
        if Thread.isMainThread {
            currentUser = user
            updateAccountInList(user)
            saveUser()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = user
                self?.updateAccountInList(user)
                self?.saveUser()
            }
        }
    }
    
    func updateContactBalance(_ contactName: String, newBalance: Double) {
        guard var user = currentUser else { return }
        if let index = user.contacts.firstIndex(where: { $0.name.lowercased() == contactName.lowercased() }) {
            user.contacts[index].balance = newBalance
            
            // Update @Published properties on main thread with immediate execution
            if Thread.isMainThread {
                currentUser = user
                updateAccountInList(user)
                saveUser()
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.currentUser = user
                    self?.updateAccountInList(user)
                    self?.saveUser()
                }
            }
        }
    }
    
    func findContact(_ name: String) -> Contact? {
        let lowercaseName = name.lowercased()
        
        // First try exact match
        if let exactMatch = currentUser?.contacts.first(where: { $0.name.lowercased() == lowercaseName }) {
            print("✅ Exact match found: '\(name)' -> '\(exactMatch.name)'")
            return exactMatch
        }
        
        // Try fuzzy matching for common variations
        if let fuzzyMatch = currentUser?.contacts.first(where: { contact in
            let contactLower = contact.name.lowercased()
            
            // Check if it's a close match (handles "Mo" vs "Moe", "John" vs "Jon", etc.)
            if contactLower.contains(lowercaseName) || lowercaseName.contains(contactLower) {
                return true
            }
            
            // Check for common name variations
            let variations = [
                ("mo", "moe"), ("moe", "mo"),
                ("john", "jon"), ("jon", "john"),
                ("mike", "michael"), ("michael", "mike"),
                ("bob", "robert"), ("robert", "bob"),
                ("alex", "alexander"), ("alexander", "alex"),
                ("chris", "christopher"), ("christopher", "chris")
            ]
            
            for (variation1, variation2) in variations {
                if (contactLower == variation1 && lowercaseName == variation2) ||
                   (contactLower == variation2 && lowercaseName == variation1) {
                    return true
                }
            }
            
            return false
        }) {
            print("✅ Fuzzy match found: '\(name)' -> '\(fuzzyMatch.name)'")
            return fuzzyMatch
        }
        
        print("❌ No contact found for: '\(name)'")
        return nil
    }
    
    func deleteContact(_ contact: Contact) {
        print("🗑️ Deleting contact: \(contact.name)")
        guard var user = currentUser else { 
            print("❌ Delete failed: no current user")
            return 
        }
        
        // Find and remove the contact
        if let index = user.contacts.firstIndex(where: { $0.id == contact.id }) {
            user.contacts.remove(at: index)
            print("✅ Contact removed from list")
            
            // Update @Published properties on main thread with immediate execution
            if Thread.isMainThread {
                currentUser = user
                updateAccountInList(user)
                saveUser()
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.currentUser = user
                    self?.updateAccountInList(user)
                    self?.saveUser()
                }
            }
            
            print("✅ Contact '\(contact.name)' deleted successfully")
        } else {
            print("❌ Contact not found in user's contact list")
        }
    }
    
    // MARK: - New Transaction Types
    
    func splitWithContact(contactName: String, amount: Double, description: String = "Split") -> Bool {
        print("🔀 Split called: contact=\(contactName), amount=\(amount)")
        guard let user = currentUser, amount > 0 else { 
            print("❌ Split failed: user=\(currentUser != nil), amount=\(amount)")
            return false 
        }
        
        guard let contact = findContact(contactName) else {
            print("❌ Split failed: contact '\(contactName)' not found")
            return false
        }
        
        let splitAmount = amount / 2.0 // Split equally between user and contact
        
        if user.balance < splitAmount {
            print("❌ Split failed: insufficient funds. Balance: \(user.balance), needed: \(splitAmount)")
            return false
        }
        
        print("💰 Current balance before split: \(user.balance)")
        
        // Create transactions
        let userTransaction = Transaction(
            type: .split,
            amount: -splitAmount,
            timestamp: Date(),
            description: "Split with \(contactName): \(description)",
            recipientName: contactName,
            senderName: user.name
        )
        
        var updatedUser = user
        updatedUser.balance -= splitAmount
        updatedUser.transactionHistory.append(userTransaction)
        
        // Update contact balance synchronously (they also pay their share)
        if let contactIndex = updatedUser.contacts.firstIndex(where: { $0.name.lowercased() == contactName.lowercased() }) {
            // Check if contact has sufficient balance
            if updatedUser.contacts[contactIndex].balance < splitAmount {
                print("❌ Contact \(contactName) has insufficient funds: \(updatedUser.contacts[contactIndex].balance), needed: \(splitAmount)")
                return false
            }
            updatedUser.contacts[contactIndex].balance -= splitAmount
            print("💰 Contact balance updated: \(contactName) paid \(splitAmount), now has \(updatedUser.contacts[contactIndex].balance)")
            
            // If this contact is also a database user, update their actual account balance
            if let contactEmail = updatedUser.contacts[contactIndex].email {
                let success = updateDatabaseUserBalance(
                    email: contactEmail,
                    amountChange: -splitAmount,
                    transactionType: .split,
                    description: "Split with \(user.name): \(description)",
                    fromUserName: user.name
                )
                if success {
                    print("✅ Also updated database user account for \(contactName)")
                }
            }
        } else {
            print("❌ Contact not found in updated user object: \(contactName)")
        }
        
        print("💰 New balance after split: \(updatedUser.balance)")
        print("💰 Contact balance after split: \(updatedUser.contacts.first(where: { $0.name.lowercased() == contactName.lowercased() })?.balance ?? 0)")
        
        // Update @Published properties on main thread with immediate execution
        if Thread.isMainThread {
            currentUser = updatedUser
            updateAccountInList(updatedUser)
            saveUser()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = updatedUser
                self?.updateAccountInList(updatedUser)
                self?.saveUser()
            }
        }
        
        print("✅ Split completed successfully")
        return true
    }
    
    func splitBetweenMultipleContacts(contactNames: [String], totalAmount: Double, description: String = "Multi-Split") -> Bool {
        print("🔀 Multi-split called: contacts=\(contactNames), totalAmount=\(totalAmount)")
        guard let user = currentUser, totalAmount > 0, !contactNames.isEmpty else { 
            print("❌ Multi-split failed: user=\(currentUser != nil), amount=\(totalAmount), contacts=\(contactNames.count)")
            return false 
        }
        
        // Calculate amount per person (including yourself)
        let totalPeople = contactNames.count + 1 // +1 for yourself
        let amountPerPerson = totalAmount / Double(totalPeople)
        print("💰 Amount per person: \(amountPerPerson) (including yourself)")
        
        // Check if user has sufficient balance for their share
        if user.balance < amountPerPerson {
            print("❌ Multi-split failed: insufficient funds. Balance: \(user.balance), needed: \(amountPerPerson)")
            return false
        }
        
        // Verify all contacts exist
        var validContacts: [Contact] = []
        print("🔍 Available contacts: \(user.contacts.map { $0.name })")
        
        for contactName in contactNames {
            print("🔍 Looking for contact: '\(contactName)'")
            if let contact = findContact(contactName) {
                validContacts.append(contact)
                print("✅ Found contact: \(contactName) with balance: \(contact.balance)")
            } else {
                print("❌ Contact not found: '\(contactName)'")
                print("🔍 Available contacts are: \(user.contacts.map { "'\($0.name)'" })")
                return false
            }
        }
        
        print("💰 Current balance before multi-split: \(user.balance)")
        print("💰 Total amount to split: \(totalAmount)")
        print("💰 Each person pays: \(amountPerPerson)")
        
        // Create transaction for user (they pay their share)
        let userTransaction = Transaction(
            type: .split,
            amount: -amountPerPerson,
            timestamp: Date(),
            description: "Split \(formatAmount(totalAmount)) with \(contactNames.joined(separator: ", ")): \(description)",
            recipientName: contactNames.joined(separator: ", "),
            senderName: user.name
        )
        
        var updatedUser = user
        updatedUser.balance -= amountPerPerson
        updatedUser.transactionHistory.append(userTransaction)
        
        // Update all contact balances synchronously (they also pay their share)
        for (index, contactName) in contactNames.enumerated() {
            if let contactIndex = updatedUser.contacts.firstIndex(where: { $0.name.lowercased() == contactName.lowercased() }) {
                // Check if contact has sufficient balance
                if updatedUser.contacts[contactIndex].balance < amountPerPerson {
                    print("❌ Contact \(contactName) has insufficient funds: \(updatedUser.contacts[contactIndex].balance), needed: \(amountPerPerson)")
                    return false
                }
                updatedUser.contacts[contactIndex].balance -= amountPerPerson
                print("💰 Updated \(contactName): paid \(amountPerPerson), balance now \(updatedUser.contacts[contactIndex].balance)")
                
                // If this contact is also a database user, update their actual account balance
                if let contactEmail = updatedUser.contacts[contactIndex].email {
                    let success = updateDatabaseUserBalance(
                        email: contactEmail,
                        amountChange: -amountPerPerson,
                        transactionType: .split,
                        description: "Split with \(user.name): \(description)",
                        fromUserName: user.name
                    )
                    if success {
                        print("✅ Also updated database user account for \(contactName)")
                    }
                }
            }
        }
        
        print("💰 New balance after multi-split: \(updatedUser.balance)")
        
        // Update @Published properties on main thread with immediate execution
        if Thread.isMainThread {
            currentUser = updatedUser
            updateAccountInList(updatedUser)
            saveUser()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = updatedUser
                self?.updateAccountInList(updatedUser)
                self?.saveUser()
            }
        }
        
        print("✅ Multi-split completed successfully")
        return true
    }
    
    private func formatAmount(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
    
    func collectSplitFromMultipleContacts(contactNames: [String], totalAmount: Double, description: String = "Collect Split") -> Bool {
        print("💰 Collect split called: contacts=\(contactNames), totalAmount=\(totalAmount)")
        guard let user = currentUser, totalAmount > 0, !contactNames.isEmpty else { 
            print("❌ Collect split failed: user=\(currentUser != nil), amount=\(totalAmount), contacts=\(contactNames.count)")
            return false 
        }
        
        // Calculate amount per person (including yourself)
        let totalPeople = contactNames.count + 1 // +1 for yourself
        let amountPerPerson = totalAmount / Double(totalPeople)
        print("💰 Amount per person: \(amountPerPerson) (including yourself)")
        
        // Verify all contacts exist
        var validContacts: [Contact] = []
        print("🔍 Available contacts: \(user.contacts.map { $0.name })")
        
        for contactName in contactNames {
            print("🔍 Looking for contact: '\(contactName)'")
            if let contact = findContact(contactName) {
                // Check if contact has sufficient balance
                if contact.balance < amountPerPerson {
                    print("❌ Contact \(contactName) has insufficient funds. Balance: \(contact.balance), needed: \(amountPerPerson)")
                    return false
                }
                validContacts.append(contact)
                print("✅ Found contact: \(contactName) with balance: \(contact.balance)")
            } else {
                print("❌ Contact not found: '\(contactName)'")
                print("🔍 Available contacts are: \(user.contacts.map { "'\($0.name)'" })")
                return false
            }
        }
        
        print("💰 Current balance before collect split: \(user.balance)")
        print("💰 Total amount to collect: \(totalAmount)")
        print("💰 Amount per person: \(amountPerPerson)")
        
        // Create transaction (you receive money)
        let userTransaction = Transaction(
            type: .split,
            amount: amountPerPerson * Double(contactNames.count), // You receive money from others
            timestamp: Date(),
            description: "Collect split with \(contactNames.joined(separator: ", ")): \(description)",
            recipientName: user.name,
            senderName: contactNames.joined(separator: ", ")
        )
        
        var updatedUser = user
        updatedUser.balance += amountPerPerson * Double(contactNames.count) // You receive money
        updatedUser.transactionHistory.append(userTransaction)
        
        // Update all contact balances (they pay money)
        for (index, contactName) in contactNames.enumerated() {
            if let contactIndex = updatedUser.contacts.firstIndex(where: { $0.name.lowercased() == contactName.lowercased() }) {
                updatedUser.contacts[contactIndex].balance -= amountPerPerson
                print("💰 Updated \(contactName): balance now \(updatedUser.contacts[contactIndex].balance) (paid \(amountPerPerson))")
                
                // If this contact is also a database user, update their actual account balance
                if let contactEmail = updatedUser.contacts[contactIndex].email {
                    let success = updateDatabaseUserBalance(
                        email: contactEmail,
                        amountChange: -amountPerPerson,
                        transactionType: .split,
                        description: "Split payment to \(user.name): \(description)",
                        fromUserName: user.name
                    )
                    if success {
                        print("✅ Also updated database user account for \(contactName)")
                    }
                }
            }
        }
        
        print("💰 New balance after collect split: \(updatedUser.balance)")
        
        // Update @Published properties on main thread with immediate execution
        if Thread.isMainThread {
            currentUser = updatedUser
            updateAccountInList(updatedUser)
            saveUser()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = updatedUser
                self?.updateAccountInList(updatedUser)
                self?.saveUser()
            }
        }
        
        print("✅ Collect split completed successfully")
        return true
    }
    
    func requestFromContact(contactName: String, amount: Double, description: String = "Request") -> Bool {
        print("📨 Request called: contact=\(contactName), amount=\(amount)")
        guard let user = currentUser, amount > 0 else { 
            print("❌ Request failed: user=\(currentUser != nil), amount=\(amount)")
            return false 
        }
        
        guard let contact = findContact(contactName) else {
            print("❌ Request failed: contact '\(contactName)' not found")
            return false
        }
        
        if contact.balance < amount {
            print("❌ Request failed: contact has insufficient funds. Contact balance: \(contact.balance), needed: \(amount)")
            return false
        }
        
        print("💰 Current balance before request: \(user.balance)")
        print("💰 Contact balance before request: \(contact.balance)")
        
        // Create transactions
        let userTransaction = Transaction(
            type: .request,
            amount: amount,
            timestamp: Date(),
            description: "Request from \(contactName): \(description)",
            recipientName: user.name,
            senderName: contactName
        )
        
        var updatedUser = user
        updatedUser.balance += amount
        updatedUser.transactionHistory.append(userTransaction)
        
        // Update contact balance synchronously (find and update in the same user object)
        if let contactIndex = updatedUser.contacts.firstIndex(where: { $0.name.lowercased() == contactName.lowercased() }) {
            updatedUser.contacts[contactIndex].balance -= amount
            print("💰 Contact balance updated: \(contactName) now has \(updatedUser.contacts[contactIndex].balance)")
        } else {
            print("❌ Contact not found in updated user object: \(contactName)")
        }
        
        print("💰 New balance after request: \(updatedUser.balance)")
        print("💰 Contact balance after request: \(updatedUser.contacts.first(where: { $0.name.lowercased() == contactName.lowercased() })?.balance ?? 0)")
        
        // Update @Published properties on main thread with immediate execution
        if Thread.isMainThread {
            currentUser = updatedUser
            updateAccountInList(updatedUser)
            saveUser()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = updatedUser
                self?.updateAccountInList(updatedUser)
                self?.saveUser()
            }
        }
        
        print("✅ Request completed successfully")
        return true
    }
    
    func sendToContact(contactName: String, amount: Double, description: String = "Send") -> Bool {
        print("📤 Send called: contact=\(contactName), amount=\(amount)")
        guard let user = currentUser, amount > 0 else { 
            print("❌ Send failed: user=\(currentUser != nil), amount=\(amount)")
            return false 
        }
        
        guard let contact = findContact(contactName) else {
            print("❌ Send failed: contact '\(contactName)' not found")
            return false
        }
        
        if user.balance < amount {
            print("❌ Send failed: insufficient funds. Balance: \(user.balance), needed: \(amount)")
            return false
        }
        
        print("💰 Current balance before send: \(user.balance)")
        print("💰 Contact balance before send: \(contact.balance)")
        
        // Create transactions
        let userTransaction = Transaction(
            type: .send,
            amount: -amount,
            timestamp: Date(),
            description: "Send to \(contactName): \(description)",
            recipientName: contactName,
            senderName: user.name
        )
        
        var updatedUser = user
        updatedUser.balance -= amount
        updatedUser.transactionHistory.append(userTransaction)
        
        // Update contact balance synchronously (find and update in the same user object)
        if let contactIndex = updatedUser.contacts.firstIndex(where: { $0.name.lowercased() == contactName.lowercased() }) {
            updatedUser.contacts[contactIndex].balance += amount
            print("💰 Contact balance updated: \(contactName) now has \(updatedUser.contacts[contactIndex].balance)")
            
            // If this contact is also a database user, update their actual account balance
            if let contactEmail = updatedUser.contacts[contactIndex].email {
                let success = updateDatabaseUserBalance(
                    email: contactEmail,
                    amountChange: amount,
                    transactionType: .deposit,
                    description: "Received from \(user.name): \(description)",
                    fromUserName: user.name
                )
                if success {
                    print("✅ Also updated database user account for \(contactName)")
                }
            }
        } else {
            print("❌ Contact not found in updated user object: \(contactName)")
        }
        
        print("💰 New balance after send: \(updatedUser.balance)")
        print("💰 Contact balance after send: \(updatedUser.contacts.first(where: { $0.name.lowercased() == contactName.lowercased() })?.balance ?? 0)")
        
        // Update @Published properties on main thread with immediate execution
        if Thread.isMainThread {
            currentUser = updatedUser
            updateAccountInList(updatedUser)
            saveUser()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = updatedUser
                self?.updateAccountInList(updatedUser)
                self?.saveUser()
            }
        }
        
        print("✅ Send completed successfully")
        return true
    }
    
    // MARK: - Name Extraction and Balance Management
    
    func extractNameFromVoiceMessage(_ voiceMessage: String) -> String {
        let lowercaseMessage = voiceMessage.lowercased()
        
        // Common patterns for extracting names from voice messages
        let namePatterns = [
            // "My name is John" or "I am John" or "This is John"
            "(?:my name is|i am|this is|call me|i'm)\\s+([a-zA-Z]+)",
            // "John here" or "John speaking"
            "([a-zA-Z]+)\\s+(?:here|speaking)",
            // "Hello, I'm John" or "Hi, this is John"
            "(?:hello|hi|hey),\\s*(?:i'm|this is|i am)\\s+([a-zA-Z]+)",
            // "John Smith" (two words)
            "([a-zA-Z]+\\s+[a-zA-Z]+)",
            // Single name at the beginning
            "^([a-zA-Z]+)\\s+(?:is|here|speaking|saying)",
            // "It's John" or "It's me, John"
            "(?:it's|its)\\s+(?:me,?\\s+)?([a-zA-Z]+)",
            // "John reporting" or "John checking in"
            "([a-zA-Z]+)\\s+(?:reporting|checking in|signing in)",
            // "Access granted John" or "Welcome John"
            "(?:access granted|welcome)\\s+([a-zA-Z]+)"
        ]
        
        for pattern in namePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: lowercaseMessage.count)
                if let match = regex.firstMatch(in: lowercaseMessage, options: [], range: range) {
                    if let nameRange = Range(match.range(at: 1), in: lowercaseMessage) {
                        let extractedName = String(lowercaseMessage[nameRange]).capitalized
                        
                        // Filter out common non-name words
                        let commonWords = ["password", "login", "access", "account", "hello", "hi", "hey", "please", "thank", "you"]
                        if !commonWords.contains(extractedName.lowercased()) && extractedName.count > 1 {
                            print("🎤 Extracted name from voice message: '\(extractedName)' from '\(voiceMessage)'")
                            return extractedName
                        }
                    }
                }
            }
        }
        
        // Fallback: if no pattern matches, try to extract first word that looks like a name
        let words = voiceMessage.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 1 && $0.allSatisfy { $0.isLetter } }
            .filter { !["password", "login", "access", "account", "hello", "hi", "hey", "please", "thank", "you"].contains($0.lowercased()) }
        
        if let firstName = words.first {
            print("🎤 Fallback name extraction: '\(firstName.capitalized)' from '\(voiceMessage)'")
            return firstName.capitalized
        }
        
        // Ultimate fallback
        print("🎤 No name found in voice message, using default")
        return "User"
    }
    
    private func generateRandomBalance() -> Double {
        // Generate a random balance between $1000 and $1500
        let minBalance: Double = 1000.0
        let maxBalance: Double = 1500.0
        let randomBalance = Double.random(in: minBalance...maxBalance)
        
        // Round to 2 decimal places
        let roundedBalance = round(randomBalance * 100) / 100
        
        print("💰 Generated random balance: $\(String(format: "%.2f", roundedBalance))")
        return roundedBalance
    }
    
    func updateUserNameFromVoice(_ voiceMessage: String) {
        guard var user = currentUser else { return }
        
        let extractedName = extractNameFromVoiceMessage(voiceMessage)
        
        // Only update if we extracted a meaningful name
        if extractedName != "User" && extractedName != user.name {
            print("📝 Updating user name from '\(user.name)' to '\(extractedName)'")
            
            user.name = extractedName
            currentUser = user
            updateAccountInList(user)
            saveUser()
        }
    }
    
    // MARK: - Contact Initialization
    
    func initializeContactsWithRandomBalances() {
        guard var user = currentUser else { 
            print("❌ No current user found for contact initialization")
            return 
        }
        
        print("👥 Starting contact initialization for user: \(user.name)")
        
        // Create diverse sample contacts with realistic balances above $1000
        let sampleContacts = [
            Contact(name: "Alice Johnson", balance: generateContactBalance(), phoneNumber: "(555) 123-4567", email: "alice.johnson@email.com"),
            Contact(name: "Bob Smith", balance: generateContactBalance(), phoneNumber: "(555) 234-5678", email: "bob.smith@email.com"),
            Contact(name: "Carol Davis", balance: generateContactBalance(), phoneNumber: "(555) 345-6789", email: "carol.davis@email.com"),
            Contact(name: "David Wilson", balance: generateContactBalance(), phoneNumber: "(555) 456-7890", email: "david.wilson@email.com"),
            Contact(name: "Emma Brown", balance: generateContactBalance(), phoneNumber: "(555) 567-8901", email: "emma.brown@email.com"),
            Contact(name: "Frank Miller", balance: generateContactBalance(), phoneNumber: "(555) 678-9012", email: "frank.miller@email.com"),
            Contact(name: "Grace Lee", balance: generateContactBalance(), phoneNumber: "(555) 789-0123", email: "grace.lee@email.com"),
            Contact(name: "Henry Taylor", balance: generateContactBalance(), phoneNumber: "(555) 890-1234", email: "henry.taylor@email.com"),
            Contact(name: "Ivy Chen", balance: generateContactBalance(), phoneNumber: "(555) 901-2345", email: "ivy.chen@email.com"),
            Contact(name: "Jack Anderson", balance: generateContactBalance(), phoneNumber: "(555) 012-3456", email: "jack.anderson@email.com")
        ]
        
        print("👥 Created \(sampleContacts.count) sample contacts:")
        for contact in sampleContacts {
            print("  📱 \(contact.name): $\(String(format: "%.2f", contact.balance))")
        }
        
        user.contacts = sampleContacts
        currentUser = user
        updateAccountInList(user)
        saveUser()
        
        print("✅ Contact initialization complete! User now has \(user.contacts.count) contacts")
    }
    
    private func generateContactBalance() -> Double {
        // Generate a random balance between $1,000 and $15,000 for contacts
        let minBalance: Double = 1000.0
        let maxBalance: Double = 15000.0
        let randomBalance = Double.random(in: minBalance...maxBalance)
        let roundedBalance = round(randomBalance * 100) / 100
        return roundedBalance
    }
    
    // MARK: - Pending Requests Management
    
    func sendMoneyRequest(toUserEmail: String, amount: Double, description: String = "Money Request") -> Bool {
        guard let currentUser = currentUser else {
            print("❌ No current user found")
            return false
        }
        
        // Find the target user
        guard let targetUser = findExistingUser(byEmail: toUserEmail) else {
            print("❌ Target user not found: \(toUserEmail)")
            return false
        }
        
        // Create the pending request
        let request = PendingRequest(
            fromUserEmail: currentUser.email,
            fromUserName: currentUser.name,
            toUserEmail: targetUser.email,
            toUserName: targetUser.name,
            amount: amount,
            description: description
        )
        
        // Add to pending requests
        pendingRequests.append(request)
        
        print("📤 Money request sent:")
        print("  💰 Amount: $\(amount)")
        print("  📧 From: \(currentUser.name) (\(currentUser.email))")
        print("  📧 To: \(targetUser.name) (\(targetUser.email))")
        print("  📝 Description: \(description)")
        
        // Save to file
        savePendingRequestsToFile()
        
        return true
    }
    
    func getPendingRequestsForCurrentUser() -> [PendingRequest] {
        guard let currentUser = currentUser else { return [] }
        
        return pendingRequests.filter { request in
            request.toUserEmail == currentUser.email && request.status == .pending
        }
    }
    
    func respondToMoneyRequest(requestId: UUID, accept: Bool) -> Bool {
        guard let requestIndex = pendingRequests.firstIndex(where: { $0.id == requestId }) else {
            print("❌ Request not found: \(requestId)")
            return false
        }
        
        let request = pendingRequests[requestIndex]
        guard let currentUser = currentUser else {
            print("❌ No current user found")
            return false
        }
        
        // Verify this request is for the current user
        guard request.toUserEmail == currentUser.email else {
            print("❌ Request is not for current user")
            return false
        }
        
        if accept {
            // Check if current user (accepter) has enough balance
            guard currentUser.balance >= request.amount else {
                print("❌ Accepter has insufficient balance: \(currentUser.balance) < \(request.amount)")
                return false
            }
            
            // Update accepter's balance (current user loses money)
            var updatedCurrentUser = currentUser
            updatedCurrentUser.balance -= request.amount
            
            // Add transaction to accepter's history
            let accepterTransaction = Transaction(
                type: .send,
                amount: request.amount,
                description: "Sent to \(request.fromUserName) (request accepted)",
                recipientName: request.fromUserName
            )
            updatedCurrentUser.transactionHistory.append(accepterTransaction)
            
            // Update the currentUser reference
            self.currentUser = updatedCurrentUser
            
            // Update requester's balance (requester gains money)
            if let requesterIndex = allAccounts.firstIndex(where: { $0.email == request.fromUserEmail }) {
                allAccounts[requesterIndex].balance += request.amount
                
                // Add transaction to requester's history
                let requesterTransaction = Transaction(
                    type: .deposit,
                    amount: request.amount,
                    description: "Received from \(request.toUserName) (request fulfilled)",
                    recipientName: request.toUserName
                )
                allAccounts[requesterIndex].transactionHistory.append(requesterTransaction)
            }
            
            print("✅ Money request accepted and completed:")
            print("  💰 Amount: $\(request.amount)")
            print("  📤 Requested by: \(request.fromUserName)")
            print("  📥 Accepted by: \(request.toUserName)")
        } else {
            print("❌ Money request declined:")
            print("  💰 Amount: $\(request.amount)")
            print("  📤 From: \(request.fromUserName)")
            print("  📥 To: \(request.toUserName)")
        }
        
        // Update request status
        pendingRequests[requestIndex].status = accept ? .accepted : .declined
        
        // Save changes
        savePendingRequestsToFile()
        saveAllAccountsToFile()
        saveUser()
        
        return true
    }
    
    func removeOldRequests() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        pendingRequests.removeAll { request in
            request.dateCreated < thirtyDaysAgo
        }
        savePendingRequestsToFile()
    }
    
    // MARK: - Account Deletion
    
    func deleteAccountWithVerification(email: String, phoneNumber: String, uniqueTag: String) -> Bool {
        print("🔍 Attempting to delete account with verification:")
        print("  📧 Email: '\(email)'")
        print("  📱 Phone: '\(phoneNumber)'")
        print("  🏷️ TAG: '\(uniqueTag)'")
        
        // Find the account that matches all three criteria
        guard let accountToDelete = allAccounts.first(where: { account in
            account.email.lowercased() == email.lowercased() &&
            account.phoneNumber == phoneNumber &&
            account.uniqueTag == uniqueTag
        }) else {
            print("❌ No account found matching all verification criteria")
            return false
        }
        
        print("✅ Account found for deletion: \(accountToDelete.name)")
        
        // Remove the account from the list
        allAccounts.removeAll { $0.email == accountToDelete.email }
        
        // If this was the current user, clear current user
        if currentUser?.email == accountToDelete.email {
            currentUser = nil
            print("🔄 Cleared current user (deleted account was logged in)")
        }
        
        // Save the updated accounts list
        saveAllAccounts()
        saveUser()
        
        print("✅ Account '\(accountToDelete.name)' deleted successfully")
        return true
    }
    
    func getAllAccountsForDeletion() -> [UserAccount] {
        return allAccounts
    }
    
    // MARK: - User Search for Contact Addition
    
    func searchExistingUsers(query: String) -> [UserAccount] {
        let lowercaseQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !lowercaseQuery.isEmpty else { return [] }
        
        // Search by name or email, excluding the current user
        return allAccounts.filter { account in
            // Don't include the current user
            guard account.email != currentUser?.email else { return false }
            
            // Search by name or email
            let nameMatch = account.name.lowercased().contains(lowercaseQuery)
            let emailMatch = account.email.lowercased().contains(lowercaseQuery)
            
            return nameMatch || emailMatch
        }
    }
    
    func findExistingUser(byEmail email: String) -> UserAccount? {
        return allAccounts.first { account in
            account.email.lowercased() == email.lowercased()
        }
    }
    
    func findExistingUser(byName name: String) -> UserAccount? {
        return allAccounts.first { account in
            account.name.lowercased() == name.lowercased()
        }
    }
}
