import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    flutterViewController.backgroundColor = .clear
    var windowFrame = self.frame
    windowFrame.size = NSSize(width: 500, height: 780)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.center()

    // Window Customization
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true
    self.title = ""
    
    // Fix black splash screen: use system-aware window background color
    self.backgroundColor = .windowBackgroundColor
    
    // Optional: Hide standard buttons if requested, but maintaining them is usually better for UX
    // self.standardWindowButton(.closeButton)?.isHidden = true
    // self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    // self.standardWindowButton(.zoomButton)?.isHidden = true

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
