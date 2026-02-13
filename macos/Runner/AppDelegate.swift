import Cocoa
import FlutterMacOS
import Security

@main
class AppDelegate: FlutterAppDelegate {
    
    private let channelName = "com.shecan.dns/control"
    private let PREVIOUS_DNS_KEY = "SHECAN_PREVIOUS_DNS"
    
    // DNS Servers
    private let SHECAN_DNS_1 = "178.22.122.101"
    private let TARGET_DNS = ["178.22.122.101", "185.51.200.1"]
    
    private var statusItem: NSStatusItem!
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)
        
        setupStatusItem()
        
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "connect":
                self.connect(result: result)
            case "disconnect":
                self.disconnect(result: result)
            case "getStatus":
                self.getStatus(result: result)
            case "getActiveInterface":
                self.getActiveInterfaceHandler(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        super.applicationDidFinishLaunching(notification)
    }
    
    // MARK: - Menu Bar
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "network.badge.shield.half.filled", accessibilityDescription: "Shecan DNS")
            } else {
                button.title = "DNS"
            }
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Connect Shecan", action: #selector(connectFromMenu), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Disconnect", action: #selector(disconnectFromMenu), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func connectFromMenu() { connect { _ in } }
    @objc func disconnectFromMenu() { disconnect { _ in } }
    
    // MARK: - Core Logic (Refactored for Sudo)
    
    private func connect(result: @escaping FlutterResult) {
        let service = getActiveService()
        if service.isEmpty {
            result(FlutterError(code: "NO_NET", message: "No active network service found", details: nil))
            return
        }
        
        let current = getDNS(service: service)
        if current != TARGET_DNS {
            UserDefaults.standard.set(current, forKey: PREVIOUS_DNS_KEY)
        }
        
        // Use Sudo Helper
        let serverArg = TARGET_DNS.joined(separator: " ")
        let cmd = "networksetup -setdnsservers \"\(service)\" \(serverArg)"
        
        SudoHelper.shared.run(command: cmd) { success, errorMsg in
            if success {
                result(true)
            } else {
                result(FlutterError(code: "AUTH_ERROR", message: errorMsg, details: nil))
            }
        }
    }
    
    private func disconnect(result: @escaping FlutterResult) {
        let service = getActiveService()
        if service.isEmpty {
            result(FlutterError(code: "NO_NET", message: "No active network service found", details: nil))
            return
        }
        
        let saved = UserDefaults.standard.stringArray(forKey: PREVIOUS_DNS_KEY) ?? []
        let serverArg: String
        if saved.isEmpty || (saved.count == 1 && saved[0].contains("There aren't any")) {
            serverArg = "Empty"
        } else {
            serverArg = saved.joined(separator: " ")
        }
        
        let cmd = "networksetup -setdnsservers \"\(service)\" \(serverArg)"
        
        SudoHelper.shared.run(command: cmd) { success, errorMsg in
            if success {
                result(true)
            } else {
                result(FlutterError(code: "AUTH_ERROR", message: errorMsg, details: nil))
            }
        }
    }
    
    private func getStatus(result: @escaping FlutterResult) {
        let service = getActiveService()
        if service.isEmpty {
            result(false)
            return
        }
        let current = getDNS(service: service)
        let isConnected = TARGET_DNS.allSatisfy { current.contains($0) }
        result(isConnected)
    }
    
    private func getActiveInterfaceHandler(result: @escaping FlutterResult) {
        let service = getActiveService()
        result(service.isEmpty ? "Unknown Connection" : service)
    }
    
    // MARK: - Network Helpers (Read-Only, No Sudo needed)
    
    private func getActiveService() -> String {
        let task = Process()
        task.launchPath = "/sbin/route"
        task.arguments = ["-n", "get", "default"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return "" }
        
        var interface = ""
        output.enumerateLines { line, stop in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("interface: ") {
                interface = trimmed.replacingOccurrences(of: "interface: ", with: "")
                stop = true
            }
        }
        if interface.isEmpty { return "" }
        return getServiceName(from: interface)
    }
    
    private func getServiceName(from interface: String) -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-listallhardwareports"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return "" }
        
        let lines = output.components(separatedBy: .newlines)
        for i in 0..<lines.count {
            if lines[i].contains("Device: \(interface)") {
                if i > 0 {
                    let prev = lines[i-1]
                    if prev.contains("Hardware Port: ") {
                        return prev.replacingOccurrences(of: "Hardware Port: ", with: "")
                    }
                }
            }
        }
        return ""
    }
    
    private func getDNS(service: String) -> [String] {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-getdnsservers", service]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        return output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Sudo Helper with Keychain

class SudoHelper {
    static let shared = SudoHelper()
    private let serviceName = "com.shecan.dns.admin"
    private let accountName = "root_access_token"
    
    // Commands to run
    func run(command: String, completion: @escaping (Bool, String?) -> Void) {
        if let password = getFromKeychain() {
            // Try with existing password
            runSudo(command: command, password: password) { success, msg in
                if success {
                    completion(true, nil)
                } else {
                    // Password might be wrong or changed, prompt again
                    self.deleteFromKeychain()
                    self.promptAndRun(command: command, completion: completion)
                }
            }
        } else {
            promptAndRun(command: command, completion: completion)
        }
    }
    
    private func promptAndRun(command: String, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Admin Access Required"
            alert.informativeText = "Please enter your Mac login password to change DNS settings. It will be stored securely in the Keychain so you won't be asked again."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            
            let input = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            alert.accessoryView = input
            
            // Focus on input
            // Focus on input
            alert.window.initialFirstResponder = input
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let password = input.stringValue
                // Try running with this password
                self.runSudo(command: command, password: password) { success, output in
                    if success {
                        self.saveToKeychain(password: password)
                        completion(true, nil)
                    } else {
                         // Alert failure
                        let failAlert = NSAlert()
                        failAlert.messageText = "Authentication Failed"
                        failAlert.informativeText = "Incorrect password or permission denied."
                        failAlert.runModal()
                        completion(false, "Authentication Failed")
                    }
                }
            } else {
                completion(false, "User Cancelled")
            }
        }
    }
    
    private func runSudo(command: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let task = Process()
        task.launchPath = "/bin/sh"
        // Use -S to read password from stdin
        task.arguments = ["-c", "echo \"\(password)\" | sudo -S \(command)"]
        
        // Setup Pipes
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        // sudo returns 0 on success
        if task.terminationStatus == 0 {
            completion(true, nil)
        } else {
            completion(false, output)
        }
    }
    
    // MARK: - Keychain Methods
    
    private func saveToKeychain(password: String) {
        guard let data = password.data(using: .utf8) else { return }
        
        // Delete any existing item
        deleteFromKeychain()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        SecItemDelete(query as CFDictionary)
    }
}
