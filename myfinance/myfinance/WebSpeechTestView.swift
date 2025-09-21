//
//  WebSpeechTestView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI
import WebKit

struct WebSpeechTestView: View {
    @StateObject private var voiceManager = WebSpeechAuthManager()
    @State private var webView: WKWebView?
    @State private var testResults: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Web Speech API Test")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Testing Web Speech Recognition")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Status indicators
                VStack(spacing: 12) {
                    HStack {
                        Text("Authorized:")
                        Spacer()
                        Text(voiceManager.isAuthorized ? "Yes" : "No")
                            .foregroundColor(voiceManager.isAuthorized ? .green : .red)
                    }
                    
                    HStack {
                        Text("Listening:")
                        Spacer()
                        Text(voiceManager.isListening ? "Yes" : "No")
                            .foregroundColor(voiceManager.isListening ? .green : .red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Test button
                Button(action: {
                    testWebSpeech()
                }) {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("Test Web Speech")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .disabled(voiceManager.isListening)
                
                // Results
                if !voiceManager.recognizedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recognized Text:")
                            .font(.headline)
                        Text(voiceManager.recognizedText)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                if !voiceManager.errorMessage.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error:")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(voiceManager.errorMessage)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Debug info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug Info:")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text("isAuthorized: \(voiceManager.isAuthorized)")
                    Text("isListening: \(voiceManager.isListening)")
                    Text("recognitionType: \(recognitionTypeString)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Web Speech Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var recognitionTypeString: String {
        return "Web Speech"
    }
    
    private func testWebSpeech() {
        print("🧪 Starting Web Speech test...")
        testResults.removeAll()
        voiceManager.reset()
        
        voiceManager.startListening()
        print("🧪 Listening started")
        
        // Monitor for results
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if voiceManager.isListening {
                print("🧪 Test timeout - stopping listening")
                voiceManager.stopListening()
            }
        }
    }
}

#Preview {
    WebSpeechTestView()
}
