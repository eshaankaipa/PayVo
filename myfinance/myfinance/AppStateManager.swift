//
//  AppStateManager.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI
import Combine

class AppStateManager: ObservableObject {
    @Published var shouldShowSplash = true
    @Published var isAppActive = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        // Reset to splash when app becomes active (foreground)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.resetToSplash()
                }
            }
            .store(in: &cancellables)
        
        // Track when app goes to background
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isAppActive = false
                }
            }
            .store(in: &cancellables)
        
        // Track when app becomes active again
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isAppActive = true
                }
            }
            .store(in: &cancellables)
    }
    
    func resetToSplash() {
        withAnimation(.easeInOut(duration: 0.5)) {
            shouldShowSplash = true
        }
        
        // Auto-transition after splash duration (reduced by 0.3 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            self.transitionFromSplash()
        }
    }
    
    func transitionFromSplash() {
        withAnimation(.easeInOut(duration: 0.8)) {
            shouldShowSplash = false
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
}
