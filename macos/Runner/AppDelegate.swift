import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    
    private let channelName = "com.shecan.dns/control"
    private let PREVIOUS_DNS_KEY = "SHECAN_PREVIOUS_DNS"
    
    // DNS Servers for Shecan
    private let SHECAN_DNS_1 = "178.22.122.101" 
    private let TARGET_DNS = ["178.22.122.101", "185.51.200.1"]
    
    private var statusItem: NSStatusItem!
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "network.badge.shield.half.filled", accessibilityDescription: "Shecan DNS")
            } else {
                // Fallback for older macOS
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
    
    @objc func connectFromMenu() {
        connect { _ in }
    }
    
    @objc func disconnectFromMenu() {
        disconnect { _ in }
    }

    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)
        
        // Initialize Status Item
        setupStatusItem()
        
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            // Helper to run safely on background if needed, but NSAppleScript needs main thread for some UI interactions?
            // Actually networksetup is CLI, but NSAppleScript `do shell script` often blocks.
            // We'll run logic here.
            
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
    
    private func connect(result: @escaping FlutterResult) {
        let service = getActiveService()
        guard !service.isEmpty else {
            result(FlutterError(code: "NO_NET", message: "No active network service found", details: nil))
            return
        }
        
        let current = getDNS(service: service)
        // Only save if current is NOT the target (avoid overwriting backup with target)
        if current != TARGET_DNS {
            UserDefaults.standard.set(current, forKey: PREVIOUS_DNS_KEY)
        }
        
        // Execute Change
        setDNS(service: service, servers: TARGET_DNS, result: result)
    }
    
    private func disconnect(result: @escaping FlutterResult) {
        let service = getActiveService()
        guard !service.isEmpty else {
            result(FlutterError(code: "NO_NET", message: "No active network service found", details: nil))
            return
        }
        
        let saved = UserDefaults.standard.stringArray(forKey: PREVIOUS_DNS_KEY) ?? []
        // If saved is empty or contains "There aren't any...", we set to Empty (Auto)
        
        if saved.isEmpty || (saved.count == 1 && saved[0].contains("There aren't any")) {
            setDNS(service: service, servers: ["Empty"], result: result)
        } else {
            setDNS(service: service, servers: saved, result: result)
        }
    }
    
    private func getStatus(result: @escaping FlutterResult) {
        let service = getActiveService()
        if service.isEmpty {
            result(false)
            return
        }
        let current = getDNS(service: service)
        // Check if current matches target
        // Note: networksetup output might have varying whitespace, but getDNS handles trimming.
        // We check if all target IPs are present.
        let isConnected = TARGET_DNS.allSatisfy { current.contains($0) }
        result(isConnected)
    }
    
    private func getActiveInterfaceHandler(result: @escaping FlutterResult) {
        let service = getActiveService()
        if service.isEmpty {
            result("Unknown Connection")
        } else {
            result(service)
        }
    }
    
    // MARK: - Core Logic
    
    private func getActiveService() -> String {
        // 1. Get default interface (e.g. en0)
        let routeTask = Process()
        routeTask.launchPath = "/sbin/route"
        routeTask.arguments = ["-n", "get", "default"]
        
        let pipe = Pipe()
        routeTask.standardOutput = pipe
        routeTask.launch()
        routeTask.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return "" }
        
        // Parse "interface: en0"
        var interface = ""
        output.enumerateLines { line, stop in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("interface: ") {
                interface = trimmed.replacingOccurrences(of: "interface: ", with: "")
                stop = true
            }
        }
        
        if interface.isEmpty { return "" }
        
        // 2. Map interface to Service Name (e.g. Wi-Fi)
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
        
        var foundService = ""
        let lines = output.components(separatedBy: .newlines)
        
        // Format:
        // Hardware Port: <Name>
        // Device: <Interface>
        
        for i in 0..<lines.count {
            if lines[i].contains("Device: \(interface)") {
                // Look backward for Hardware Port
                if i > 0 {
                    let prev = lines[i-1]
                    if prev.contains("Hardware Port: ") {
                        foundService = prev.replacingOccurrences(of: "Hardware Port: ", with: "")
                        break
                    }
                }
            }
        }
        
        return foundService
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
    
    private func setDNS(service: String, servers: [String], result: @escaping FlutterResult) {
        let serverArg = servers.joined(separator: " ")
        // AppleScript to run with privileges
        // Escape quotes in service name just in case
        let scriptSource = "do shell script \"networksetup -setdnsservers \\\"\(service)\\\" \(serverArg)\" with administrator privileges"
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            script.executeAndReturnError(&error)
            if let err = error {
                let msg = err[NSAppleScript.errorMessage] as? String ?? "Unknown Error"
                result(FlutterError(code: "AUTH_ERROR", message: msg, details: nil))
            } else {
                result(true)
            }
        } else {
            result(FlutterError(code: "SCRIPT_INIT_ERROR", message: "Failed to init script", details: nil))
        }
    }
}
