import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Voice Manager
class VoiceManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var errorMessage = ""
    @Published var isAuthorized = false
    
    // MARK: - Private Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Initialization
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        requestPermissions()
    }
    
    deinit {
        stopListening()
        print("🧹 VoiceManager deallocated - cleanup completed")
    }
    
    // MARK: - Permission Management
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isAuthorized = (authStatus == .authorized)
                if authStatus != .authorized {
                    self.errorMessage = "Speech recognition permission required"
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if !granted {
                    self.errorMessage = "Microphone permission required"
                }
            }
        }
    }
    
    // MARK: - Speech Recognition
    func startListening() {
        guard isAuthorized else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Speech recognition not authorized"
            }
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Speech recognizer not available"
            }
            return
        }
        
        // Stop any existing recognition
        stopListening()
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Unable to create recognition request"
            }
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Audio session error: \(error.localizedDescription)"
            }
            return
        }
        
        // Create recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let result = result {
                    let newText = result.bestTranscription.formattedString
                    print("🎤 Voice recognition result: '\(newText)' (isFinal: \(result.isFinal))")
                    
                    // Only update recognizedText if we have actual content
                    // This prevents empty final results from overwriting good transcriptions
                    if !newText.isEmpty {
                        self.recognizedText = newText
                        self.errorMessage = ""
                        print("✅ Updated recognized text to: '\(newText)'")
                    } else if result.isFinal {
                        print("⚠️ Final result is empty, keeping previous text: '\(self.recognizedText)'")
                    }
                    
                    // If this is the final result, we can stop listening
                    if result.isFinal {
                        print("🏁 Final transcription received. Keeping text: '\(self.recognizedText)'")
                        self.stopListening()
                    }
                }
                
                if let error = error {
                    // Only show error if it's not a cancellation
                    if !error.localizedDescription.contains("cancel") {
                        self.errorMessage = "Recognition error: \(error.localizedDescription)"
                    }
                    self.stopListening()
                }
            }
        }
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isListening = true
                self.recognizedText = ""
                self.errorMessage = ""
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Audio engine error: \(error.localizedDescription)"
            }
        }
    }
    
    func stopListening() {
        // Stop audio engine first
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Remove tap from audio engine safely
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Update UI state
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isListening = false
        }
    }
    
    func reset() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.recognizedText = ""
            self.errorMessage = ""
            self.isListening = false
        }
    }
    
}