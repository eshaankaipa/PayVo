//
//  VoiceBiometricManager.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import Foundation
import Combine
import SwiftUI
import Speech
import AVFoundation

struct VoiceSample: Codable {
    let audioData: Data
    let transcript: String
    let timestamp: Date
    let duration: TimeInterval
    let pitch: Float
    let amplitude: Float
}

class VoiceBiometricManager: ObservableObject {
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var errorMessage = ""
    @Published var isAuthorized = false
    @Published var recordingProgress: Double = 0.0
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioRecorder: AVAudioRecorder?
    private var audioFile: AVAudioFile?
    
    // Audio analysis properties
    private var audioBuffer: [Float] = []
    private let audioAnalyzer = AVAudioUnitEQ(numberOfBands: 0)
    
    init() {
        checkPermissions()
        setupAudioSession()
    }
    
    deinit {
        stopRecording()
    }
    
    func reset() {
        stopRecording()
        recognizedText = ""
        errorMessage = ""
        recordingProgress = 0.0
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
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
    
    func startRecording() -> VoiceSample? {
        guard isAuthorized else {
            errorMessage = "Speech recognition not authorized"
            return nil
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return nil
        }
        
        // Always stop any existing recording first
        stopRecording()
        
        // Wait a moment for cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performStartRecording()
        }
        
        return nil // Will return actual sample when recording stops
    }
    
    private func performStartRecording() {
        // Create audio file for recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("voice_sample_\(Date().timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            // Start speech recognition
            startSpeechRecognition()
            
            isRecording = true
            recordingProgress = 0.0
            
            // Simulate recording progress
            simulateRecordingProgress()
            
        } catch {
            errorMessage = "Audio recording error: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() -> VoiceSample? {
        guard isRecording else { return nil }
        
        // Stop audio recorder safely
        audioRecorder?.stop()
        audioRecorder = nil
        
        // Cancel recognition task safely
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Stop audio engine safely
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        isRecording = false
        recordingProgress = 0.0
        
        // For now, return a simulated voice sample
        // In a real implementation, you would analyze the recorded audio
        return createSimulatedVoiceSample()
    }
    
    private func createSimulatedVoiceSample() -> VoiceSample {
        let audioData = Data() // In real implementation, this would be the actual audio data
        
        // If no recognized text, simulate some common voice passwords
        let transcript = recognizedText.isEmpty ? simulateVoicePassword() : recognizedText
        let timestamp = Date()
        let duration = 3.0 // Simulated duration
        let pitch = Float.random(in: 80...300) // Simulated pitch range
        let amplitude = Float.random(in: 0.1...1.0) // Simulated amplitude
        
        return VoiceSample(
            audioData: audioData,
            transcript: transcript,
            timestamp: timestamp,
            duration: duration,
            pitch: pitch,
            amplitude: amplitude
        )
    }
    
    private func simulateVoicePassword() -> String {
        // For demo purposes, simulate realistic voice recognition
        // This simulates what a user might actually say when trying to login
        let possibleInputs = [
            "my voice password",
            "hello world",
            "access my account", 
            "open sesame",
            "password one two three",
            "voice authentication",
            "my secret phrase",
            "login please",
            "unlock account",
            "hi i am mohit",
            "test password",
            "wrong password",
            "something random",
            "incorrect phrase",
            "not my password",
            "random words",
            "different text"
        ]
        
        // Randomly select what the user "said"
        let simulatedInput = possibleInputs.randomElement() ?? "my voice password"
        recognizedText = simulatedInput
        
        print("🎤 Voice Recognition Simulated: User said '\(simulatedInput)'")
        return simulatedInput
    }
    
    private func startSpeechRecognition() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.recognizedText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    self?.errorMessage = "Recognition error: \(error.localizedDescription)"
                }
            }
        }
        
        // Configure audio engine for real-time speech recognition
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Remove any existing tap first
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Audio engine error: \(error.localizedDescription)"
            // Don't fail the recording if speech recognition fails
            print("Speech recognition failed, but continuing with recording")
        }
    }
    
    private func simulateRecordingProgress() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.isRecording {
                self.recordingProgress += 0.033 // 3 seconds total
                if self.recordingProgress >= 1.0 {
                    timer.invalidate()
                    self.recordingProgress = 1.0
                }
            } else {
                timer.invalidate()
            }
        }
    }
    
    func compareVoiceSamples(_ sample1: VoiceSample, _ sample2: VoiceSample) -> Bool {
        // Text comparison (must match)
        let textMatch = sample1.transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                       sample2.transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard textMatch else { 
            print("🔍 Voice Biometric: Text doesn't match - rejecting")
            return false 
        }
        
        // Voice characteristics comparison
        let pitchDifference = abs(sample1.pitch - sample2.pitch)
        let amplitudeDifference = abs(sample1.amplitude - sample2.amplitude)
        let durationDifference = abs(sample1.duration - sample2.duration)
        
        // VERY STRICT tolerance thresholds for exact voice matching
        let pitchTolerance: Float = 10.0 // Hz (very strict - must be within 10Hz)
        let amplitudeTolerance: Float = 0.05 // Very strict - must be within 5% amplitude
        let durationTolerance: TimeInterval = 0.3 // seconds (very strict - within 0.3 seconds)
        
        let pitchMatch = pitchDifference <= pitchTolerance
        let amplitudeMatch = amplitudeDifference <= amplitudeTolerance
        let durationMatch = durationDifference <= durationTolerance
        
        print("🔍 Voice Biometric Comparison:")
        print("  📊 Pitch: \(sample1.pitch) vs \(sample2.pitch) (diff: \(pitchDifference), tolerance: \(pitchTolerance)) - \(pitchMatch ? "✅" : "❌")")
        print("  📊 Amplitude: \(sample1.amplitude) vs \(sample2.amplitude) (diff: \(amplitudeDifference), tolerance: \(amplitudeTolerance)) - \(amplitudeMatch ? "✅" : "❌")")
        print("  📊 Duration: \(sample1.duration) vs \(sample2.duration) (diff: \(durationDifference), tolerance: \(durationTolerance)) - \(durationMatch ? "✅" : "❌")")
        
        // Require ALL 3 characteristics to match for strict voice verification
        let allCharacteristicsMatch = pitchMatch && amplitudeMatch && durationMatch
        
        print("  🎯 Voice Match Result: \(allCharacteristicsMatch ? "✅ MATCH" : "❌ NO MATCH")")
        
        return allCharacteristicsMatch
    }
    
    func getVoiceMatchConfidence(_ sample1: VoiceSample, _ sample2: VoiceSample) -> Double {
        // Calculate confidence based on how close the characteristics are
        let pitchDifference = abs(sample1.pitch - sample2.pitch)
        let amplitudeDifference = abs(sample1.amplitude - sample2.amplitude)
        let durationDifference = abs(sample1.duration - sample2.duration)
        
        // VERY STRICT confidence calculation - only high confidence for very close matches
        let pitchScore = max(0, 1.0 - (Double(pitchDifference) / 10.0)) // Much stricter: 10Hz tolerance
        let amplitudeScore = max(0, 1.0 - (Double(amplitudeDifference) / 0.05)) // Much stricter: 5% tolerance
        let durationScore = max(0, 1.0 - (durationDifference / 0.3)) // Much stricter: 0.3s tolerance
        
        let rawConfidence = (pitchScore + amplitudeScore + durationScore) / 3.0
        
        // Additional penalty for any deviation from exact match
        let strictConfidence = rawConfidence * 0.8 // Reduce confidence by 20% to be more strict
        
        print("🔍 Strict Confidence Calculation:")
        print("  📊 Pitch Score: \(pitchScore) (diff: \(pitchDifference)Hz)")
        print("  📊 Amplitude Score: \(amplitudeScore) (diff: \(amplitudeDifference))")
        print("  📊 Duration Score: \(durationScore) (diff: \(durationDifference)s)")
        print("  📊 Raw Confidence: \(rawConfidence)")
        print("  📊 Strict Confidence: \(strictConfidence)")
        
        return strictConfidence
    }
}
