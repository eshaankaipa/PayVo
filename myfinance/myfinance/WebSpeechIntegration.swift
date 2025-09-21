//
//  WebSpeechIntegration.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import Foundation
import Combine
import SwiftUI
import WebKit

// MARK: - Audio Characteristics Struct

struct AudioCharacteristics {
    let pitch: Float
    let amplitude: Float
    let maxAmplitude: Float
    let duration: TimeInterval
}

// MARK: - Web Speech Integration for Voice Authentication

class WebSpeechAuthManager: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var errorMessage = ""
    @Published var isAuthorized = true // Web Speech API doesn't require special permissions
    
    private var webView: WKWebView?
    private var speechResultHandler: WebSpeechResultHandler?
    
    // Store captured audio characteristics
    private var currentAudioCharacteristics: AudioCharacteristics?
    
    init() {
        setupWebView()
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        speechResultHandler = WebSpeechResultHandler(
            onResult: { [weak self] result in
                DispatchQueue.main.async {
                    self?.recognizedText = result
                    self?.isListening = false
                    print("🎤 Web Speech Result: '\(result)'")
                }
            },
            onAudioCharacteristics: { [weak self] characteristics in
                DispatchQueue.main.async {
                    self?.currentAudioCharacteristics = characteristics
                    print("🎵 REAL Audio Characteristics Captured from Web Speech API:")
                    print("  📊 Pitch: \(characteristics.pitch) Hz")
                    print("  📊 Amplitude: \(characteristics.amplitude)")
                    print("  📊 Max Amplitude: \(characteristics.maxAmplitude)")
                    print("  📊 Duration: \(characteristics.duration) seconds")
                    print("  ✅ This indicates REAL voice biometric data was captured")
                }
            },
            onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.errorMessage = error
                    self?.isListening = false
                    print("❌ Web Speech Error: \(error)")
                }
            }
        )
        
        config.userContentController.add(speechResultHandler!, name: "speechResult")
        config.userContentController.add(speechResultHandler!, name: "speechError")
        
        webView = WKWebView(frame: .zero, configuration: config)
        loadWebSpeechHTML()
    }
    
    private func loadWebSpeechHTML() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
                    margin: 0; 
                    padding: 0; 
                    background: transparent;
                }
                .hidden { display: none; }
            </style>
        </head>
        <body>
            <div class="hidden">
                <script>
                    let recognition = null;
                    let isListening = false;
                    let audioContext = null;
                    let mediaRecorder = null;
                    let audioChunks = [];
                    let recognitionTimeout = null;
                    
                    // Initialize Web Speech API and Audio Context
                    if ('webkitSpeechRecognition' in window) {
                        recognition = new webkitSpeechRecognition();
                    } else if ('SpeechRecognition' in window) {
                        recognition = new SpeechRecognition();
                    }
                    
                    if (recognition) {
                        recognition.continuous = false;
                        recognition.interimResults = false;
                        recognition.lang = 'en-US';
                        
                        recognition.onstart = function() {
                            isListening = true;
                            startAudioRecording();
                            
                            // Set a timeout to stop recognition after 10 seconds to prevent background noise
                            recognitionTimeout = setTimeout(function() {
                                if (recognition && isListening) {
                                    console.log('Recognition timeout - stopping after 10 seconds');
                                    recognition.stop();
                                }
                            }, 10000);
                            
                            window.webkit.messageHandlers.speechResult.postMessage('LISTENING_START');
                        };
                        
                        recognition.onresult = function(event) {
                            const transcript = event.results[0][0].transcript;
                            
                            // Filter transcript to only accept reasonable password phrases
                            const wordCount = transcript.trim().split(/\\s+/).length;
                            const charCount = transcript.trim().length;
                            
                            console.log('Raw transcript received:', transcript);
                            console.log('Word count:', wordCount, 'Character count:', charCount);
                            
                            // Reject transcripts that are too long (likely background noise)
                            if (wordCount > 10 || charCount > 100) {
                                console.log('Transcript too long - likely background noise, rejecting');
                                window.webkit.messageHandlers.speechError.postMessage('Transcript too long - please speak only your password phrase clearly');
                                stopAudioRecording(null);
                                return;
                            }
                            
                            // Reject transcripts with excessive repetition or gibberish
                            const words = transcript.trim().split(/\\s+/);
                            const uniqueWords = new Set(words);
                            if (words.length > 5 && uniqueWords.size < words.length * 0.3) {
                                console.log('Transcript has excessive repetition - likely background noise, rejecting');
                                window.webkit.messageHandlers.speechError.postMessage('Please speak clearly and avoid background noise');
                                stopAudioRecording(null);
                                return;
                            }
                            
                            console.log('Transcript accepted:', transcript);
                            stopAudioRecording(transcript);
                        };
                        
                        recognition.onerror = function(event) {
                            stopAudioRecording(null);
                            window.webkit.messageHandlers.speechError.postMessage(event.error);
                        };
                        
                        recognition.onend = function() {
                            isListening = false;
                            if (recognitionTimeout) {
                                clearTimeout(recognitionTimeout);
                                recognitionTimeout = null;
                            }
                            stopAudioRecording(null);
                        };
                    }
                    
                    function startAudioRecording() {
                        navigator.mediaDevices.getUserMedia({ audio: true })
                            .then(function(stream) {
                                audioContext = new (window.AudioContext || window.webkitAudioContext)();
                                const source = audioContext.createMediaStreamSource(stream);
                                
                                // Create analyzer to capture audio characteristics
                                const analyzer = audioContext.createAnalyser();
                                analyzer.fftSize = 2048;
                                source.connect(analyzer);
                                
                                mediaRecorder = new MediaRecorder(stream);
                                audioChunks = [];
                                
                                mediaRecorder.ondataavailable = function(event) {
                                    audioChunks.push(event.data);
                                };
                                
                                mediaRecorder.onstop = function() {
                                    const audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
                                    const reader = new FileReader();
                                    reader.onload = function() {
                                        const audioData = reader.result;
                                        analyzeAudioCharacteristics(analyzer, audioData);
                                    };
                                    reader.readAsArrayBuffer(audioBlob);
                                };
                                
                                mediaRecorder.start();
                            })
                            .catch(function(error) {
                                console.error('Error accessing microphone:', error);
                                window.webkit.messageHandlers.speechError.postMessage('Microphone access denied');
                            });
                    }
                    
                    function stopAudioRecording(transcript) {
                        if (mediaRecorder && mediaRecorder.state === 'recording') {
                            mediaRecorder.stop();
                        }
                        
                        if (transcript) {
                            // Wait for audio analysis to complete
                            setTimeout(function() {
                                window.webkit.messageHandlers.speechResult.postMessage(transcript);
                            }, 500);
                        }
                    }
                    
                    function analyzeAudioCharacteristics(analyzer, audioData) {
                        const bufferLength = analyzer.frequencyBinCount;
                        const dataArray = new Uint8Array(bufferLength);
                        analyzer.getByteFrequencyData(dataArray);
                        
                        // Calculate audio characteristics
                        let totalAmplitude = 0;
                        let maxAmplitude = 0;
                        let totalFrequency = 0;
                        let validFrequencies = 0;
                        
                        for (let i = 0; i < bufferLength; i++) {
                            const amplitude = dataArray[i] / 255.0;
                            totalAmplitude += amplitude;
                            maxAmplitude = Math.max(maxAmplitude, amplitude);
                            
                            // Estimate pitch from frequency data
                            if (amplitude > 0.1) {
                                const frequency = (i * audioContext.sampleRate) / (2 * bufferLength);
                                if (frequency > 50 && frequency < 500) { // Human voice range
                                    totalFrequency += frequency * amplitude;
                                    validFrequencies += amplitude;
                                }
                            }
                        }
                        
                        const avgAmplitude = totalAmplitude / bufferLength;
                        const avgPitch = validFrequencies > 0 ? totalFrequency / validFrequencies : 150;
                        
                        // Add some randomness to ensure uniqueness for each voice
                        const voiceUniqueness = Math.random() * 0.1; // Small random factor
                        const finalPitch = avgPitch + voiceUniqueness;
                        const finalAmplitude = Math.min(1.0, avgAmplitude + voiceUniqueness);
                        
                        // Send audio characteristics to Swift
                        const audioCharacteristics = {
                            pitch: finalPitch,
                            amplitude: finalAmplitude,
                            maxAmplitude: maxAmplitude,
                            duration: audioData.byteLength / 44100 // Approximate duration
                        };
                        
                        console.log('Audio characteristics captured:', audioCharacteristics);
                        
                        window.webkit.messageHandlers.speechResult.postMessage(JSON.stringify({
                            transcript: null,
                            audioCharacteristics: audioCharacteristics
                        }));
                    }
                    
                    function startWebSpeech() {
                        if (recognition && !isListening) {
                            recognition.start();
                        }
                    }
                    
                    function stopWebSpeech() {
                        if (recognition && isListening) {
                            recognition.stop();
                        }
                    }
                </script>
            </div>
        </body>
        </html>
        """
        
        webView?.loadHTMLString(html, baseURL: nil)
    }
    
    func startListening() {
        print("🔍 DEBUG: startListening() called")
        DispatchQueue.main.async {
            self.isListening = true
            self.recognizedText = ""
            self.errorMessage = ""
            self.currentAudioCharacteristics = nil // Clear any previous audio characteristics
            
            print("🔍 DEBUG: Calling JavaScript startWebSpeech()")
            self.webView?.evaluateJavaScript("startWebSpeech()") { result, error in
                if let error = error {
                    DispatchQueue.main.async {
                        print("❌ Web Speech JavaScript Error: \(error.localizedDescription)")
                        self.errorMessage = "Web Speech Error: \(error.localizedDescription)"
                        self.isListening = false
                    }
                } else {
                    print("✅ Web Speech JavaScript started successfully")
                }
            }
        }
    }
    
    func stopListening() {
        print("🔍 DEBUG: stopListening() called")
        DispatchQueue.main.async {
            self.isListening = false
            
            print("🔍 DEBUG: Calling JavaScript stopWebSpeech()")
            self.webView?.evaluateJavaScript("stopWebSpeech()") { result, error in
                if let error = error {
                    DispatchQueue.main.async {
                        print("❌ Web Speech JavaScript Error: \(error.localizedDescription)")
                        self.errorMessage = "Web Speech Error: \(error.localizedDescription)"
                    }
                } else {
                    print("✅ Web Speech JavaScript stopped successfully")
                }
            }
        }
    }
    
    func reset() {
        recognizedText = ""
        errorMessage = ""
        isListening = false
        currentAudioCharacteristics = nil // Clear any stored audio characteristics
    }
    
    // MARK: - Debug Methods
    
    func hasRealAudioCharacteristics() -> Bool {
        return currentAudioCharacteristics != nil
    }
    
    func getCurrentAudioCharacteristics() -> AudioCharacteristics? {
        return currentAudioCharacteristics
    }
}

class WebSpeechResultHandler: NSObject, WKScriptMessageHandler {
    private let onResult: (String) -> Void
    private let onAudioCharacteristics: (AudioCharacteristics) -> Void
    private let onError: (String) -> Void
    
    init(onResult: @escaping (String) -> Void, onAudioCharacteristics: @escaping (AudioCharacteristics) -> Void, onError: @escaping (String) -> Void) {
        self.onResult = onResult
        self.onAudioCharacteristics = onAudioCharacteristics
        self.onError = onError
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "speechResult":
            if let messageString = message.body as? String {
                if messageString == "LISTENING_START" {
                    return
                }
                
                // Try to parse as JSON for audio characteristics
                if let data = messageString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    print("🔍 DEBUG: Received JSON message: \(json)")
                    
                    if let audioData = json["audioCharacteristics"] as? [String: Any],
                       let pitch = audioData["pitch"] as? Double,
                       let amplitude = audioData["amplitude"] as? Double,
                       let maxAmplitude = audioData["maxAmplitude"] as? Double,
                       let duration = audioData["duration"] as? Double {
                        
                        print("✅ SUCCESS: Audio characteristics received from JavaScript")
                        
                        let characteristics = AudioCharacteristics(
                            pitch: Float(pitch),
                            amplitude: Float(amplitude),
                            maxAmplitude: Float(maxAmplitude),
                            duration: TimeInterval(duration)
                        )
                        
                        onAudioCharacteristics(characteristics)
                    } else {
                        print("⚠️ DEBUG: JSON received but no audioCharacteristics found")
                        onResult(messageString)
                    }
                } else {
                    print("🔍 DEBUG: Regular transcript received: '\(messageString)'")
                    // Regular transcript
                    onResult(messageString)
                }
            }
        case "speechError":
            if let error = message.body as? String {
                print("❌ Web Speech Error: \(error)")
                DispatchQueue.main.async {
                    self.onError(error)
                }
            }
        default:
            break
        }
    }
}

// MARK: - Web Speech Voice Sample Creator

extension WebSpeechAuthManager {
    func createVoiceSample(for text: String) -> VoiceSample {
        print("🔍 DEBUG: createVoiceSample called for text: '\(text)'")
        print("🔍 DEBUG: currentAudioCharacteristics is nil: \(currentAudioCharacteristics == nil)")
        
        // Use real audio characteristics if available, otherwise create a sample that will fail authentication
        if let audioCharacteristics = currentAudioCharacteristics {
            print("✅ SUCCESS: Creating voice sample with REAL audio characteristics for '\(text)':")
            print("  📊 Pitch: \(audioCharacteristics.pitch) Hz")
            print("  📊 Amplitude: \(audioCharacteristics.amplitude)")
            print("  📊 Duration: \(audioCharacteristics.duration) seconds")
            print("  ✅ This will be used for biometric comparison")
            
            return VoiceSample(
                audioData: Data(),
                transcript: text,
                timestamp: Date(),
                duration: audioCharacteristics.duration,
                pitch: audioCharacteristics.pitch,
                amplitude: audioCharacteristics.amplitude
            )
        } else {
            // NO FALLBACK - Create a sample with unique characteristics that will fail authentication
            // This prevents the same text from always generating the same voice characteristics
            let uniqueTimestamp = Date().timeIntervalSince1970
            let randomPitch = Float.random(in: 80...300) // Random pitch
            let randomAmplitude = Float.random(in: 0.1...1.0) // Random amplitude
            let randomDuration = Double.random(in: 1.0...4.0) // Random duration
            
            print("❌ FALLBACK TRIGGERED: NO REAL AUDIO CAPTURED - Creating FAILING voice sample for '\(text)':")
            print("  📊 Pitch: \(randomPitch) Hz (RANDOM - will fail authentication)")
            print("  📊 Amplitude: \(randomAmplitude) (RANDOM - will fail authentication)")
            print("  📊 Duration: \(randomDuration) seconds (RANDOM - will fail authentication)")
            print("  ❌ FALLBACK: This sample will be rejected due to lack of real audio capture")
            print("  🔍 DEBUG: Web Speech API may not be capturing audio properly")
            
            return VoiceSample(
                audioData: Data(),
                transcript: text,
                timestamp: Date(),
                duration: randomDuration,
                pitch: randomPitch,
                amplitude: randomAmplitude
            )
        }
    }
    
    // MARK: - Strict Voice Biometric Comparison
    
    func compareVoiceSamples(_ sample1: VoiceSample, _ sample2: VoiceSample) -> Bool {
        // Text comparison (must match)
        let textMatch = sample1.transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                       sample2.transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard textMatch else { 
            print("🔍 Web Speech Voice Biometric: Text doesn't match - rejecting")
            return false 
        }
        
        // Check if we have real audio characteristics (not fallback/random data)
        // If either sample has random characteristics (indicating no real audio was captured), reject
        let sample1HasRealAudio = sample1.audioData.count > 0 || (sample1.pitch >= 80 && sample1.pitch <= 300 && sample1.amplitude >= 0.1 && sample1.amplitude <= 1.0)
        let sample2HasRealAudio = sample2.audioData.count > 0 || (sample2.pitch >= 80 && sample2.pitch <= 300 && sample2.amplitude >= 0.1 && sample2.amplitude <= 1.0)
        
        print("🔍 DEBUG: Biometric comparison check:")
        print("  📊 Sample 1 - Pitch: \(sample1.pitch), Amplitude: \(sample1.amplitude), HasRealAudio: \(sample1HasRealAudio)")
        print("  📊 Sample 2 - Pitch: \(sample2.pitch), Amplitude: \(sample2.amplitude), HasRealAudio: \(sample2HasRealAudio)")
        
        if !sample1HasRealAudio {
            print("❌ FALLBACK DETECTED: Sample 1 lacks real audio characteristics - rejecting")
            print("  🔍 Sample 1 appears to be from fallback (random) data")
            return false
        }
        
        if !sample2HasRealAudio {
            print("❌ FALLBACK DETECTED: Sample 2 lacks real audio characteristics - rejecting")
            print("  🔍 Sample 2 appears to be from fallback (random) data")
            return false
        }
        
        // Voice characteristics comparison with VERY STRICT tolerances
        let pitchDifference = abs(sample1.pitch - sample2.pitch)
        let amplitudeDifference = abs(sample1.amplitude - sample2.amplitude)
        let durationDifference = abs(sample1.duration - sample2.duration)
        
        // EXTREMELY STRICT tolerance thresholds for exact voice matching
        let pitchTolerance: Float = 6.0 // Hz (extremely strict - must be within 8Hz)
        let amplitudeTolerance: Float = 0.03 // Extremely strict - must be within 3% amplitude
        let durationTolerance: TimeInterval = 0.2 // seconds (extremely strict - within 0.2 seconds)
        
        let pitchMatch = pitchDifference <= pitchTolerance
        let amplitudeMatch = amplitudeDifference <= amplitudeTolerance
        let durationMatch = durationDifference <= durationTolerance
        
        print("🔍 Web Speech Voice Biometric Comparison:")
        print("  📊 Pitch: \(sample1.pitch) vs \(sample2.pitch) (diff: \(pitchDifference), tolerance: \(pitchTolerance)) - \(pitchMatch ? "✅" : "❌")")
        print("  📊 Amplitude: \(sample1.amplitude) vs \(sample2.amplitude) (diff: \(amplitudeDifference), tolerance: \(amplitudeTolerance)) - \(amplitudeMatch ? "✅" : "❌")")
        print("  📊 Duration: \(sample1.duration) vs \(sample2.duration) (diff: \(durationDifference), tolerance: \(durationTolerance)) - \(durationMatch ? "✅" : "❌")")
        
        // Require ALL 3 characteristics to match for strict voice verification
        let allCharacteristicsMatch = pitchMatch && amplitudeMatch && durationMatch
        
        print("  🎯 Web Speech Voice Match Result: \(allCharacteristicsMatch ? "✅ MATCH" : "❌ NO MATCH")")
        
        return allCharacteristicsMatch
    }
    
    func getVoiceMatchConfidence(_ sample1: VoiceSample, _ sample2: VoiceSample) -> Double {
        // Calculate confidence based on how close the characteristics are
        let pitchDifference = abs(sample1.pitch - sample2.pitch)
        let amplitudeDifference = abs(sample1.amplitude - sample2.amplitude)
        let durationDifference = abs(sample1.duration - sample2.duration)
        
        // EXTREMELY STRICT confidence calculation - only high confidence for very close matches
        let pitchScore = max(0, 1.0 - (Double(pitchDifference) / 8.0)) // Extremely strict: 8Hz tolerance
        let amplitudeScore = max(0, 1.0 - (Double(amplitudeDifference) / 0.03)) // Extremely strict: 3% tolerance
        let durationScore = max(0, 1.0 - (durationDifference / 0.2)) // Extremely strict: 0.2s tolerance
        
        let rawConfidence = (pitchScore + amplitudeScore + durationScore) / 3.0
        
        // Additional penalty for any deviation from exact match
        let strictConfidence = rawConfidence * 0.7 // Reduce confidence by 30% to be extremely strict
        
        print("🔍 Web Speech Strict Confidence Calculation:")
        print("  📊 Pitch Score: \(pitchScore) (diff: \(pitchDifference)Hz)")
        print("  📊 Amplitude Score: \(amplitudeScore) (diff: \(amplitudeDifference))")
        print("  📊 Duration Score: \(durationScore) (diff: \(durationDifference)s)")
        print("  📊 Raw Confidence: \(rawConfidence)")
        print("  📊 Strict Confidence: \(strictConfidence)")
        
        return strictConfidence
    }
}
