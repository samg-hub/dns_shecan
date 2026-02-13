# DNS Changer 

A modern, lightweight macOS application built with Flutter to quickly switch between different DNS profiles. Designed specifically for users in Iran to easily toggle DNS settings like Cloudflare, and custom configurations.

## ✨ Features

- 🚀 **Quick Toggle**: Switch your system DNS with a single click.
- 📁 **Profile Management**: Use predefined profiles or create your own custom DNS settings.
- 🖥️ **Menu Bar Integration**: Access and control the application directly from the macOS status bar.
- 🔒 **Secure Authorization**: Securely stores admin credentials in the macOS Keychain for a seamless experience (no more constant password prompts).
- 🛡️ **VPN Detection**: Intelligent logic to detect active VPNs and prevent conflicts.
- 🌚 **Modern UI**: Clean, responsive interface built with Flutter, supporting system dark/light modes.

## 🛠 Built With

- **Flutter**: For the cross-platform (macOS) UI.
- **Swift**: For native macOS system calls (`networksetup`).
- **Provider**: For robust state management.
- **Shared Preferences**: Local persistence for custom profiles.
- **macOS Keychain**: Secure storage for system authorization.

## 🚀 Getting Started

### Prerequisites

- macOS 10.15 or later.
- Flutter SDK installed.
- Xcode installed (for build).

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/dns_shecan.git
   ```

2. Navigate to the project directory:
   ```bash
   cd dns_shecan
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the application:
   ```bash
   flutter run -d macos
   ```

## 📖 How it Works

The application uses the macOS native `networksetup` utility to modify the DNS settings of your active network interface. 
- **Authorization**: Since changing DNS requires root privileges, the app prompts for your system password on the first use and stores it securely in the Keychain.
- **Network Interface**: It automatically detects your primary active network interface (Wi-Fi, Ethernet, etc.) to apply changes correctly.

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to improve the app.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

