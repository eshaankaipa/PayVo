import Foundation
import Combine
import AVFoundation

// MARK: - Voice Command Service
class VoiceCommandService: ObservableObject {
    
    // MARK: - Transaction Type
    enum TransactionType {
        case send, split, request, requestFromUser
    }
    
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var lastResult = ""
    @Published var errorMessage = ""
    @Published var showConfirmationDialog = false
    @Published var pendingTransaction: PendingTransaction?
    
    // MARK: - Private Properties
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Command Processing
    func processVoiceCommand(_ command: String, userDatabase: UserDatabase) {
        guard !isProcessing else { 
            print("⚠️ Command already processing, ignoring: '\(command)'")
            return 
        }
        
        print("🚀 Starting command processing: '\(command)'")
        
        // Set processing state
        isProcessing = true
        errorMessage = ""
        lastResult = "Processing command..."
        
        // Process command synchronously to avoid threading issues during app termination
        let result = executeCommand(command, userDatabase: userDatabase)
        print("✅ Command result: '\(result.message)'")
        
        // Update UI properties
        lastResult = result.message
        isProcessing = false
        
        if result.shouldSpeak {
            speakResponse(result.message)
        }
    }
    
    // MARK: - Private Methods
    private func executeCommand(_ command: String, userDatabase: UserDatabase) -> CommandResult {
        let lowercaseCommand = command.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🎤 Processing command: '\(command)' -> '\(lowercaseCommand)'")
        
        // Check balance
        if lowercaseCommand.contains("balance") || lowercaseCommand.contains("check balance") || lowercaseCommand.contains("how much") {
            let balance = userDatabase.getCurrentBalance()
            print("💰 Balance check: \(formatAmount(balance))")
            return CommandResult(
                message: "Your current balance is \(formatAmount(balance))",
                shouldSpeak: true
            )
        }
        
        // Split
        if lowercaseCommand.contains("split") {
            print("🎯 Split command detected: '\(lowercaseCommand)'")
            print("🔍 Available contacts: \(userDatabase.getContacts().map { $0.name })")
            if let amount = extractAmount(from: lowercaseCommand) {
                print("🔍 Extracted amount: \(amount)")
                // First try to extract multiple contact names
                let multipleContactNames = extractMultipleContactNames(from: lowercaseCommand)
                print("🔍 Extracted multiple contact names: \(multipleContactNames)")
                
            if !multipleContactNames.isEmpty {
                
                // Filter out "me" from the contact names - only pass actual contacts to the database
                let actualContactNames = multipleContactNames.filter { $0.lowercased() != "me" }
                let totalPeople = actualContactNames.count + 1 // +1 for you
                
                print("💰 Split between multiple people: \(formatAmount(amount)) split between \(actualContactNames.joined(separator: ", ")) and you")
                print("🔍 Actual contact names in split: \(actualContactNames)")
                print("🔍 Total amount: \(amount)")
                print("🔍 Total people (including you): \(totalPeople)")
                
                // Test each contact name lookup
                for contactName in actualContactNames {
                    if let contact = userDatabase.findContact(contactName) {
                        print("✅ Contact lookup successful: '\(contactName)' -> '\(contact.name)'")
                    } else {
                        print("❌ Contact lookup failed: '\(contactName)'")
                    }
                }
                
                let success = userDatabase.splitBetweenMultipleContacts(contactNames: actualContactNames, totalAmount: amount, description: "Voice Split Between")
                if success {
                    let perPersonAmount = amount / Double(totalPeople)
                    return CommandResult(
                        message: "Successfully split \(formatAmount(amount)) between \(actualContactNames.joined(separator: ", ")) and you. Each person pays \(formatAmount(perPersonAmount))",
                        shouldSpeak: true
                    )
                } else {
                    return CommandResult(
                        message: "Failed to split between \(actualContactNames.joined(separator: ", ")). Please check the contact names and their balances.",
                        shouldSpeak: true
                    )
                }
                } else {
                    print("🔍 No multiple contact names found, trying single contact extraction")
                    // Single person split (original logic)
                    if let contactName = extractContactName(from: lowercaseCommand) {
                        // Check balance threshold before splitting
                        if checkBalanceThreshold(amount: amount, contactName: contactName, type: .split, description: "Voice Split", userDatabase: userDatabase) {
                            print("🔀 Single split: \(formatAmount(amount)) with \(contactName)")
                            let success = userDatabase.splitWithContact(contactName: contactName, amount: amount, description: "Voice Split")
                            if success {
                                return CommandResult(
                                    message: "Successfully split \(formatAmount(amount)) with \(contactName)",
                                    shouldSpeak: true
                                )
                            } else {
                                return CommandResult(
                                    message: "Failed to split with \(contactName). Please check the contact name and your balance.",
                                    shouldSpeak: true
                                )
                            }
                        } else {
                            // Confirmation dialog shown, don't process yet
                            return CommandResult(
                                message: "Transaction pending confirmation...",
                                shouldSpeak: false
                            )
                        }
                    } else {
                        print("❌ No contact names found at all")
                        return CommandResult(
                            message: "Please specify contact names. For example: 'split 100 dollars with Alice' or 'split 150 between Alice, Bob, Carol'",
                            shouldSpeak: true
                        )
                    }
                }
            } else {
                return CommandResult(
                    message: "Please specify an amount to split. For example: 'split 100 dollars with Alice' or 'split 150 between Alice, Bob, Carol'",
                    shouldSpeak: true
                )
            }
        }
        
        // Request
        if lowercaseCommand.contains("request") || lowercaseCommand.contains("ask for") {
            print("🎯 Request command detected: '\(lowercaseCommand)'")
            print("🔍 Available contacts: \(userDatabase.getContacts().map { $0.name })")
            
            if let amount = extractAmount(from: lowercaseCommand) {
                print("🔍 Extracted amount: \(amount)")
                if let contactName = extractContactName(from: lowercaseCommand) {
                    print("📨 Requesting: \(formatAmount(amount)) from \(contactName)")
                    
                    // Check if this is a database user first
                    if let databaseUser = userDatabase.findExistingUser(byName: contactName) {
                        print("✅ Database user found: '\(contactName)' -> '\(databaseUser.name)' (\(databaseUser.email))")
                        
                        // This is a request to a database user - send a money request
                        let success = userDatabase.sendMoneyRequest(toUserEmail: databaseUser.email, amount: amount, description: "Voice Request")
                        
                        if success {
                            return CommandResult(
                                message: "Money request sent to \(databaseUser.name). They will receive a notification to accept or decline your request.",
                                shouldSpeak: true
                            )
                        } else {
                            return CommandResult(
                                message: "Failed to send money request to \(databaseUser.name). Please try again.",
                                shouldSpeak: true
                            )
                        }
                    } else {
                        // Check if this is a regular contact
                        if let contact = userDatabase.findContact(contactName) {
                            print("✅ Contact lookup successful: '\(contactName)' -> '\(contact.name)'")
                        } else {
                            print("❌ Contact lookup failed: '\(contactName)'")
                        }
                        
                        // Check balance threshold before requesting (based on contact's balance)
                        if checkBalanceThreshold(amount: amount, contactName: contactName, type: .request, description: "Voice Request", userDatabase: userDatabase) {
                            let success = userDatabase.requestFromContact(contactName: contactName, amount: amount, description: "Voice Request")
                            if success {
                                return CommandResult(
                                    message: "Successfully requested \(formatAmount(amount)) from \(contactName)",
                                    shouldSpeak: true
                                )
                            } else {
                                return CommandResult(
                                    message: "Failed to request from \(contactName). Please check the contact name and their balance.",
                                    shouldSpeak: true
                                )
                            }
                        } else {
                            // Confirmation dialog shown, don't process yet
                            return CommandResult(
                            message: "Transaction pending confirmation...",
                            shouldSpeak: false
                        )
                        }
                    }
                } else {
                    print("❌ No contact name found in request command")
                    return CommandResult(
                        message: "Please specify a contact name. For example: 'request 50 dollars from Eric'",
                        shouldSpeak: true
                    )
                }
            } else {
                print("❌ No amount found in request command")
                return CommandResult(
                    message: "Please specify an amount to request. For example: 'request 50 dollars from Eric'",
                    shouldSpeak: true
                )
            }
        }
        
        // Send
        if lowercaseCommand.contains("send") || lowercaseCommand.contains("give") || lowercaseCommand.contains("pay") {
            print("🎯 Send command detected in: '\(lowercaseCommand)'")
            
            let contactName = extractContactName(from: lowercaseCommand)
            let amount = extractAmount(from: lowercaseCommand)
            
            print("🔍 Parsed contact name: \(contactName ?? "nil")")
            print("🔍 Parsed amount: \(amount != nil ? formatAmount(amount!) : "nil")")
            
                    if let contactName = contactName {
                        if let amount = amount {
                            // Check balance threshold before sending
                            if checkBalanceThreshold(amount: amount, contactName: contactName, type: .send, description: "Voice Send", userDatabase: userDatabase) {
                                // Amount specified in command
                                print("📤 Sending: \(formatAmount(amount)) to \(contactName)")
                                let success = userDatabase.sendToContact(contactName: contactName, amount: amount, description: "Voice Send")
                                if success {
                                    return CommandResult(
                                        message: "Successfully sent \(formatAmount(amount)) to \(contactName)",
                                        shouldSpeak: true
                                    )
                                } else {
                                    return CommandResult(
                                        message: "Failed to send to \(contactName). Please check the contact name and your balance.",
                                        shouldSpeak: true
                                    )
                                }
                            } else {
                                // Confirmation dialog shown, don't process yet
                                return CommandResult(
                                    message: "Transaction pending confirmation...",
                                    shouldSpeak: false
                                )
                            }
                        } else {
                            // No amount specified, use default amount
                            let defaultAmount = 25.0
                            print("📤 No amount specified, using default: \(formatAmount(defaultAmount)) to \(contactName)")
                            let success = userDatabase.sendToContact(contactName: contactName, amount: defaultAmount, description: "Voice Send (Default Amount)")
                            if success {
                                return CommandResult(
                                    message: "Successfully sent \(formatAmount(defaultAmount)) to \(contactName) (default amount)",
                                    shouldSpeak: true
                                )
                            } else {
                                return CommandResult(
                                    message: "Failed to send to \(contactName). Please check the contact name and your balance.",
                                    shouldSpeak: true
                                )
                            }
                        }
            } else {
                print("❌ No contact name found in command: '\(lowercaseCommand)'")
                return CommandResult(
                    message: "Please specify a contact name. For example: 'send 25 dollars to Ms' or 'send money to John'",
                    shouldSpeak: true
                )
            }
        }
        
        // Transaction history
        if lowercaseCommand.contains("transaction") || lowercaseCommand.contains("history") {
            let transactions = userDatabase.getTransactionHistory()
            if transactions.isEmpty {
                return CommandResult(
                    message: "No transactions found.",
                    shouldSpeak: true
                )
            } else {
                return CommandResult(
                    message: "You have \(transactions.count) transactions. Check the transaction history page for details.",
                    shouldSpeak: true
                )
            }
        }
        
        // Contacts
        if lowercaseCommand.contains("contacts") || lowercaseCommand.contains("contact") {
            let contacts = userDatabase.getContacts()
            if contacts.isEmpty {
                return CommandResult(
                    message: "No contacts found. Add contacts in the contacts page.",
                    shouldSpeak: true
                )
            } else {
                return CommandResult(
                    message: "You have \(contacts.count) contacts. Check the contacts page for details.",
                    shouldSpeak: true
                )
            }
        }
        
        // Help
        if lowercaseCommand.contains("help") {
            return CommandResult(
                message: "Available commands: check balance, split amount with contact, send amount to contact, request amount from contact (or database user), show transactions, show contacts, help",
                shouldSpeak: true
            )
        }
        
        // Default response
        return CommandResult(
            message: "Command not recognized. Try: check balance, split with contact, send to contact, or request from contact",
            shouldSpeak: true
        )
    }
    
    private func extractAmount(from input: String) -> Double? {
        print("🔍 Extracting amount from: '\(input)'")
        
        let wordNumbers: [String: Double] = [
            "fifty": 50, "one hundred": 100, "hundred": 100, "two hundred": 200,
            "three hundred": 300, "five hundred": 500, "one thousand": 1000,
            "thousand": 1000, "two thousand": 2000, "five thousand": 5000,
            "ten": 10, "twenty": 20, "thirty": 30, "forty": 40, "sixty": 60,
            "seventy": 70, "eighty": 80, "ninety": 90, "one": 1, "two": 2,
            "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9
        ]
        
        // Try to find word-based numbers first
        for (word, value) in wordNumbers {
            if input.contains(word) {
                print("🎯 Found word amount: \(word) = \(value)")
                return value
            }
        }
        
        // Try to find numeric amounts
        let patterns = [
            "\\$?(\\d+(?:\\.\\d{1,2})?)",  // $100 or 100.50
            "(\\d+)\\s*dollars?",          // 100 dollars
            "(\\d+)\\s*bucks?"             // 100 bucks
        ]
        
        for (index, pattern) in patterns.enumerated() {
            print("🔍 Trying pattern \(index + 1): \(pattern)")
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: input.utf16.count)
                if let match = regex.firstMatch(in: input, options: [], range: range) {
                    if let amountRange = Range(match.range(at: 1), in: input),
                       let amount = Double(String(input[amountRange])) {
                        print("🎯 Found numeric amount: \(amount)")
                        return amount
                    }
                }
            }
        }
        
        print("❌ No amount found in: '\(input)'")
        return nil
    }
    
    private func extractContactName(from input: String) -> String? {
        let lowercaseInput = input.lowercased()
        print("🔍 Extracting contact name from: '\(input)'")
        
        // Common patterns for extracting contact names
        let patterns = [
            // "request $100 from Eric" - specific pattern for request with amount
            "(?:request|ask for)\\s+\\$?\\d+(?:\\.\\d{1,2})?\\s+(?:dollars?\\s+)?from\\s+([a-zA-Z]+)",
            // "send money from me to Ms" or "send to John" - handles short names
            "(?:send|give|pay)\\s+(?:money\\s+)?(?:from\\s+me\\s+)?to\\s+([a-zA-Z]+)",
            // "split with Ms" or "request from John"
            "(?:split\\s+with|request\\s+from)\\s+([a-zA-Z]+)",
            // "send $100 to Ms" - handles amounts
            "(?:send|give|pay)\\s+\\$?\\d+(?:\\.\\d{1,2})?\\s+(?:to\\s+)?([a-zA-Z]+)",
            // "send to John Smith" - handles full names
            "(?:send|give|pay)\\s+(?:money\\s+)?(?:from\\s+me\\s+)?to\\s+([a-zA-Z]+(?:\\s+[a-zA-Z]+)?)",
            // "split with John Smith" - handles full names
            "(?:split\\s+with|request\\s+from)\\s+([a-zA-Z]+(?:\\s+[a-zA-Z]+)?)",
            // Generic patterns
            "(?:with|to|from)\\s+([a-zA-Z]+(?:\\s+[a-zA-Z]+)?)",
            "([a-zA-Z]+(?:\\s+[a-zA-Z]+)?)\\s+(?:here|speaking|balance)"
        ]
        
        for (index, pattern) in patterns.enumerated() {
            print("🔍 Trying contact pattern \(index + 1): \(pattern)")
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: input.utf16.count)
                if let match = regex.firstMatch(in: input, options: [], range: range) {
                    if let nameRange = Range(match.range(at: 1), in: input) {
                        let extractedName = String(input[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if !extractedName.isEmpty {
                            print("🎯 Extracted contact name: '\(extractedName)' from '\(input)' using pattern \(index + 1)")
                            return extractedName
                        }
                    }
                }
            }
        }
        
        print("❌ No contact name found in: '\(input)'")
        return nil
    }
    
    private func extractMultipleContactNames(from input: String) -> [String] {
        let lowercaseInput = input.lowercased()
        print("🔍 Extracting multiple contact names from: '\(input)'")
        
        // Look for "split $X between Person1, Person2, Person3" pattern
        let splitPattern = "split\\s+\\$?\\d+(?:\\.\\d{1,2})?\\s+between\\s+(.+)"
        
        if let regex = try? NSRegularExpression(pattern: splitPattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                if let namesRange = Range(match.range(at: 1), in: input) {
                    let namesString = String(input[namesRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    print("🎯 Found names string: '\(namesString)'")
                    
                    // Keep all names including "me" - we'll handle "me" in the split logic
                    let cleanedNamesString = namesString
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    print("🎯 Cleaned names string: '\(cleanedNamesString)'")
                    
                    // Split by commas and "and", then clean up names
                    let names = cleanedNamesString.components(separatedBy: ",")
                        .flatMap { $0.components(separatedBy: " and ") }
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                        .map { $0.capitalized }
                    
                    print("🎯 Extracted contact names: \(names)")
                    return names
                }
            }
        }
        
        // Fallback: look for "split with Person1 and Person2" pattern
        let andPattern = "split\\s+(?:\\$?\\d+(?:\\.\\d{1,2})?\\s+)?with\\s+(.+)"
        
        if let regex = try? NSRegularExpression(pattern: andPattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: input.utf16.count)
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                if let namesRange = Range(match.range(at: 1), in: input) {
                    let namesString = String(input[namesRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    print("🎯 Found names string (and pattern): '\(namesString)'")
                    
                    // Split by "and" and clean up names
                    let names = namesString.components(separatedBy: " and ")
                        .flatMap { $0.components(separatedBy: ",") }
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                        .map { $0.capitalized }
                    
                    print("🎯 Extracted contact names (and pattern): \(names)")
                    return names
                }
            }
        }
        
        print("❌ No multiple contact names found in: '\(input)'")
        return []
    }
    
    private func formatAmount(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
    
    private func speakResponse(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Confirmation Methods
    private func checkBalanceThreshold(amount: Double, contactName: String, type: TransactionType, description: String, userDatabase: UserDatabase) -> Bool {
        let currentBalance = userDatabase.getCurrentBalance()
        let percentage = (amount / currentBalance) * 100
        
        print("💰 Balance check: amount=\(amount), balance=\(currentBalance), percentage=\(percentage)%")
        
        if percentage > 15.0 {
            print("⚠️ Amount exceeds 15% threshold, showing confirmation dialog")
            
            let pendingTransaction = PendingTransaction(
                type: type,
                contactName: contactName,
                amount: amount,
                description: description,
                percentageOfBalance: percentage
            )
            
            self.pendingTransaction = pendingTransaction
            self.showConfirmationDialog = true
            
            // Voice alert
            let alertMessage = "Warning: This transaction is \(String(format: "%.1f", percentage))% of your balance. Do you want to proceed?"
            speakResponse(alertMessage)
            
            return false // Don't proceed immediately
        }
        
        return true // Proceed with transaction
    }
    
    func confirmTransaction(userDatabase: UserDatabase) {
        guard let transaction = pendingTransaction else { return }
        
        print("✅ User confirmed transaction: \(transaction.type) \(transaction.amount) to \(transaction.contactName)")
        
        var success = false
        
        switch transaction.type {
        case .send:
            success = userDatabase.sendToContact(contactName: transaction.contactName, amount: transaction.amount, description: transaction.description)
        case .split:
            success = userDatabase.splitWithContact(contactName: transaction.contactName, amount: transaction.amount, description: transaction.description)
        case .request:
            success = userDatabase.requestFromContact(contactName: transaction.contactName, amount: transaction.amount, description: transaction.description)
        case .requestFromUser:
            // Find the user by name and send a money request
            if let targetUser = userDatabase.findExistingUser(byName: transaction.contactName) {
                success = userDatabase.sendMoneyRequest(toUserEmail: targetUser.email, amount: transaction.amount, description: transaction.description)
            } else {
                success = false
            }
        }
        
        if success {
            let responseMessage = "Transaction confirmed and completed successfully."
            lastResult = responseMessage
            speakResponse(responseMessage)
        } else {
            let errorMessage = "Transaction failed. Please check the contact name and balances."
            lastResult = errorMessage
            speakResponse(errorMessage)
        }
        
        // Clear pending transaction
        pendingTransaction = nil
        showConfirmationDialog = false
        isProcessing = false
    }
    
    func cancelTransaction() {
        print("❌ User cancelled transaction")
        
        let cancelMessage = "Transaction cancelled."
        lastResult = cancelMessage
        speakResponse(cancelMessage)
        
        // Clear pending transaction
        pendingTransaction = nil
        showConfirmationDialog = false
        isProcessing = false
    }
    
    deinit {
        // Ensure proper cleanup when VoiceCommandService is deallocated
        speechSynthesizer.stopSpeaking(at: .immediate)
        print("🧹 VoiceCommandService deallocated - cleanup completed")
    }
}

// MARK: - Pending Transaction
struct PendingTransaction {
    let type: VoiceCommandService.TransactionType
    let contactName: String
    let amount: Double
    let description: String
    let percentageOfBalance: Double
}


// MARK: - Command Result
struct CommandResult {
    let message: String
    let shouldSpeak: Bool
}
