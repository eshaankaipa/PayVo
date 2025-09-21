//
//  SimpleVoiceManager.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import Foundation
import Combine
import SwiftUI
import Speech
import AVFoundation

class SimpleVoiceManager: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var errorMessage = ""
    @Published var isAuthorized = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = (status == .authorized)
                if status != .authorized {
                    self?.errorMessage = "Speech recognition access required"
                }
            }
        }
    }
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    func startListening() {
        guard isAuthorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }
        
        isListening = true
        errorMessage = ""
        recognizedText = ""
        
        // Simulate voice recognition with user input
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.stopListening()
            
            // For demo purposes, simulate different voice passwords
            // In a real app, this would be actual speech recognition
            let demoPasswords = [
                "my voice password",
                "hello world",
                "access my account",
                "open sesame",
                "password one two three"
            ]
            
            // Randomly select a demo password
            let randomPassword = demoPasswords.randomElement() ?? "my voice password"
            self.recognizedText = randomPassword
            
            print("🎤 Voice Input Simulated: '\(randomPassword)'")
            self.processVoiceCommand(randomPassword)
        }
    }
    
    func stopListening() {
        isListening = false
    }
    
    private func processVoiceCommand(_ text: String) {
        let lowercaseText = text.lowercased()
        
        if lowercaseText.contains("login") || lowercaseText.contains("sign in") {
            print("Voice command detected: LOGIN")
            // Handle login command here
        } else if lowercaseText.contains("merge") || lowercaseText.contains("merge account") {
            print("Voice command detected: MERGE ACCOUNT")
            // Handle merge account command here
        }
    }
}
