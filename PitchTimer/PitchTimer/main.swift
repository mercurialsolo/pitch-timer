import AppKit
import Foundation

// Parse command line arguments
var initialDuration: Int?
var cliMode = false

let arguments = CommandLine.arguments
var i = 1
while i < arguments.count {
    let arg = arguments[i]

    if arg == "-d" || arg == "--duration" {
        if i + 1 < arguments.count, let duration = Int(arguments[i + 1]), duration > 0 {
            initialDuration = duration
            i += 2
        } else {
            i += 1
        }
    } else if arg == "--cli" || arg == "-c" {
        cliMode = true
        i += 1
    } else {
        i += 1
    }
}

if cliMode {
    // Run in CLI mode
    let preferences = Preferences()
    if let duration = initialDuration {
        preferences.timerDuration = duration
    }

    let cliTimer = CLITimer(preferences: preferences)
    cliTimer.run()
} else {
    // Run in GUI mode
    let app = NSApplication.shared
    let delegate = AppDelegate(initialDuration: initialDuration)
    app.delegate = delegate
    app.run()
}
