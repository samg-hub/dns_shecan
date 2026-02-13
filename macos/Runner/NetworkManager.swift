import Foundation
import SystemConfiguration

class NetworkManager {
    static let shared = NetworkManager()
    
    // Use SystemConfiguration to get primary interface more reliably
    func getPrimaryInterface() -> String? {
        // Use SCDynamicStore to find the primary service
        // This is more robust than "route get default" for finding the logical primary service
        // However, for altering DNS via networksetup, we need the "User Friendly Name" (e.g. Wi-Fi)
        // or the Hardware Port name.
        
        // Fallback to route get default as it reflects the actual routing table
        let task = Process()
        task.launchPath = "/sbin/route"
        task.arguments = ["-n", "get", "default"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }
        
        var interface = ""
        output.enumerateLines { line, stop in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("interface: ") {
                interface = trimmed.replacingOccurrences(of: "interface: ", with: "")
                stop = true
            }
        }
        
        // Exclude VPN interfaces (utun, ppp) if we want to change physical interface DNS
        // Usually VPNs override DNS anyway. If we want to force DNS, we might need to change it on the physical link.
        // But if VPN is active, changing physical link DNS might not affect traffic if VPN tunnels everything.
        // For robustness, if we detect a VPN interface, we might want to warn the user or try to find the underlying physical interface.
        // For now, we will stick to the default route interface, but filter common VPN prefixes if needed.
        // Or better: Let's find the Service Name for this interface.
        
        return interface.isEmpty ? nil : interface
    }
    
    func getServiceName(from interface: String) -> String? {
        // Use networksetup -listallhardwareports
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-listallhardwareports"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }
        
        // Parse output
        let lines = output.components(separatedBy: .newlines)
        for i in 0..<lines.count {
            if lines[i].contains("Device: \(interface)") {
                // Look backward for Hardware Port
                if i > 0 {
                    let prev = lines[i-1]
                    if prev.contains("Hardware Port: ") {
                        return prev.replacingOccurrences(of: "Hardware Port: ", with: "")
                    }
                }
            }
        }
        
        // If not found in hardware ports, it might be a VPN or virtual interface
        // networksetup might not be able to set DNS on "utun1" directly via name.
        return nil
    }
    
    // Check if an interface name looks like a VPN (utun, ppp, ipsec)
    func isVPN(interface: String) -> Bool {
        return interface.hasPrefix("utun") || interface.hasPrefix("ppp") || interface.hasPrefix("ipsec")
    }
    
    // Find the first active physical service (Wi-Fi, Ethernet) even if VPN is primary
    func findActivePhysicalService() -> String? {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-listallnetworkservices"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }
        
        let services = output.components(separatedBy: .newlines).filter { 
            !$0.isEmpty && !$0.contains("An asterisk") && !$0.contains("Note:") 
        }
        
        // Priority list: Ethernet, Wi-Fi. Others like "Thunderbolt Bridge" might be valid too.
        // We need to check if they have an IP address.
        
        for service in services {
             if hasIPAddress(service: service) {
                 return service
             }
        }
        
        return nil
    }
    
    private func hasIPAddress(service: String) -> Bool {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-getinfo", service]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return false }
        
        // Look for "IP address: x.x.x.x" (IPv4)
        // If it says "IP address: (null)" or is empty, it's not active.
        return output.contains("IP address: ") && !output.contains("IP address: (null)")
    }
}
