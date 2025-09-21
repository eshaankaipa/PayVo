# PayVo - Voice-Controlled Finance App

## 🎯 Overview

PayVo is a cutting-edge iOS finance application that revolutionizes personal money management through advanced voice recognition technology. Built with SwiftUI and powered by Apple's Speech framework, PayVo enables users to perform complex financial transactions using natural voice commands.

## ✨ Key Features

### 🎤 Voice-Controlled Transactions
- **Natural Language Processing**: Execute transactions using conversational commands
- **Smart Command Recognition**: Understands complex voice instructions with context
- **Real-time Voice Feedback**: Audio confirmation for all transactions
- **Multi-language Support**: Optimized for English voice recognition

### 💰 Comprehensive Financial Operations
- **Send Money**: Transfer funds to contacts with voice commands
- **Request Money**: Ask for payments from contacts or database users
- **Split Bills**: Divide expenses among multiple people automatically
- **Balance Checking**: Instant account balance inquiries
- **Transaction History**: Complete audit trail of all financial activities

### 🔐 Advanced Security
- **Voice Biometric Authentication**: Secure login using voice patterns
- **Multi-factor Authentication**: Email, phone, and unique tag verification
- **Transaction Confirmation**: Smart alerts for high-value transactions (>15% of balance)
- **Secure Data Storage**: Local encryption with UserDefaults and file persistence

### 👥 Contact Management
- **Smart Contact System**: Automatic contact discovery and management
- **Balance Synchronization**: Real-time contact balance updates
- **Fuzzy Name Matching**: Intelligent contact name recognition
- **Database Integration**: Seamless connection between contacts and user accounts

### 🎨 Modern UI/UX
- **SwiftUI Architecture**: Modern, responsive interface design
- **Smooth Animations**: Fluid transitions and micro-interactions
- **Accessibility**: Voice-first design for inclusive user experience
- **Dark/Light Theme Support**: Adaptive color schemes

## 🚀 Getting Started

### Prerequisites

- **Xcode 14.0+**
- **iOS 14.0+**
- **macOS 12.0+** (for development)
- **Apple Developer Account** (for device testing)

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/eshaankaipa/PayVo.git
   cd PayVo
   ```

2. **Open in Xcode**
   ```bash
   open PayVo.xcodeproj
   ```

3. **Configure Project**
   - Select your development team in project settings
   - Update bundle identifier if needed
   - Ensure deployment target is iOS 14.0+

4. **Build and Run**
   - Select target device or simulator
   - Press `Cmd + R` to build and run

### First-Time Setup

1. **Launch the App**: Open PayVo on your iOS device
2. **Create Account**: Follow the voice-guided setup process
3. **Voice Authentication**: Record your voice password for secure access
4. **Add Contacts**: Import or manually add your contacts
5. **Start Transacting**: Use voice commands to manage your finances

## 🎤 Voice Commands

### Basic Commands
```
"Check my balance"
"What's my balance?"
"How much money do I have?"
```

### Transaction Commands
```
"Send 50 dollars to John"
"Request 25 dollars from Alice"
"Split 100 dollars with Bob"
"Split 150 between Alice, Bob, and Carol"
```

### Information Commands
```
"Show my transactions"
"Show my contacts"
"Help"
```

### Advanced Commands
```
"Send money to John" (uses default $25)
"Request from database user Sarah"
"Split 200 between multiple contacts"
```

## 🏗️ Architecture

### Core Components

- **VoiceManager**: Handles speech recognition and audio processing
- **VoiceCommandService**: Processes natural language commands
- **UserDatabase**: Manages user accounts, transactions, and contacts
- **VoiceBiometricManager**: Handles voice authentication
- **WebSpeechIntegration**: Advanced voice processing capabilities

### Data Models

- **UserAccount**: Complete user profile with authentication
- **Transaction**: Financial transaction records
- **Contact**: Contact management with balance tracking
- **PendingRequest**: Money request system

### Key Features Implementation

- **Voice Recognition**: Apple Speech Framework integration
- **Data Persistence**: Dual storage (UserDefaults + File system)
- **Real-time Updates**: Combine publishers for reactive UI
- **Error Handling**: Comprehensive error management and user feedback

## 📱 Screenshots

<div align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/logo.png" alt="PayVo App Icon" width="100" height="100">
  
  *Voice-controlled interface with intuitive design*
</div>

## 🔧 Configuration

### Voice Recognition Settings
- **Language**: English (US)
- **Recognition Mode**: Continuous speech
- **Audio Quality**: High-quality recording
- **Noise Cancellation**: Built-in iOS processing

### Security Configuration
- **Voice Authentication**: Custom biometric thresholds
- **Transaction Limits**: Configurable percentage-based alerts
- **Data Encryption**: Local encryption for sensitive data

## 🚀 Deployment

### For Development
1. **Xcode Setup**: Configure signing and capabilities
2. **Device Testing**: Install on physical iOS device
3. **Voice Permissions**: Grant microphone and speech recognition access

### For Production
1. **App Store Preparation**:
   - Update version and build numbers
   - Configure app metadata
   - Prepare screenshots and descriptions

2. **Distribution**:
   - Archive the project
   - Upload to App Store Connect
   - Submit for review

### For Enterprise
1. **Internal Distribution**:
   - Configure enterprise provisioning
   - Build for internal testing
   - Distribute via MDM or direct installation

## 🛠️ Development

### Project Structure
```
PayVo/
├── Views/
│   ├── HomePageView.swift
│   ├── VoiceAuthView.swift
│   ├── MoneyOptionsView.swift
│   └── ...
├── Models/
│   ├── UserDatabase.swift
│   └── ...
├── Services/
│   ├── VoiceManager.swift
│   ├── VoiceCommandService.swift
│   └── ...
└── Assets/
    └── ...
```

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming
- **Speech Framework**: Voice recognition
- **AVFoundation**: Audio processing
- **UserDefaults**: Data persistence

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📋 Requirements

### System Requirements
- **iOS**: 14.0 or later
- **Device**: iPhone or iPad
- **Storage**: 50MB minimum
- **Network**: Internet connection for voice recognition

### Permissions Required
- **Microphone**: For voice input
- **Speech Recognition**: For command processing
- **Local Storage**: For data persistence

## 🔒 Security & Privacy

### Data Protection
- **Local Storage**: All data stored locally on device
- **No Cloud Sync**: Privacy-first approach
- **Encryption**: Sensitive data encrypted at rest
- **Voice Data**: Processed locally, not stored

### Privacy Features
- **No Tracking**: No analytics or user tracking
- **Offline Capable**: Core functionality works offline
- **Data Control**: Users have full control over their data

## 🐛 Troubleshooting

### Common Issues

**Voice Recognition Not Working**
- Check microphone permissions
- Ensure good audio environment
- Verify iOS version compatibility

**Transaction Failures**
- Verify contact names are correct
- Check account balances
- Ensure proper voice command format

**App Crashes**
- Restart the application
- Check iOS version compatibility
- Clear app data if necessary

### Debug Mode
Enable debug logging by setting `DEBUG_MODE = true` in build settings.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/eshaankaipa/PayVo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/eshaankaipa/PayVo/discussions)
- **Email**: [Contact Developer](mailto:your-email@example.com)

## 🎯 Roadmap

### Upcoming Features
- [ ] Multi-language voice support
- [ ] Advanced analytics dashboard
- [ ] Integration with banking APIs
- [ ] Group expense management
- [ ] Voice-activated bill reminders
- [ ] Advanced security features

### Version History
- **v1.0.0**: Initial release with core voice features
- **v1.1.0**: Enhanced contact management
- **v1.2.0**: Advanced voice commands
- **v1.3.0**: Security improvements

## 🙏 Acknowledgments

- Apple Speech Framework team
- SwiftUI community
- iOS development community
- Beta testers and contributors

---

<div align="center">
  <strong>Built with ❤️ using SwiftUI and Apple's Speech Framework</strong>
  
  [Download on the App Store](https://apps.apple.com/app/payvo) | [View on GitHub](https://github.com/eshaankaipa/PayVo)
</div>
