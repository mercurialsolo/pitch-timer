import Foundation

class CLITimer: TimerManagerDelegate {
    private let timerManager: TimerManager
    private let preferences: Preferences
    private var runLoop: RunLoop?

    init(preferences: Preferences) {
        self.preferences = preferences
        self.timerManager = TimerManager(preferences: preferences)
        self.timerManager.delegate = self
    }

    func run() {
        print("PitchTimer CLI Mode")
        print("==================")
        print("Commands:")
        print("  [space] - Start/Stop timer")
        print("  r - Reset timer")
        print("  q - Quit")
        print("  +/- - Increase/Decrease duration by 1 minute")
        print("")
        print("Timer: \(formatTime(preferences.timerDuration))")
        print("")

        // Set terminal to raw mode for immediate key input
        setRawMode(true)

        // Start input listener in background
        DispatchQueue.global(qos: .userInteractive).async {
            self.listenForInput()
        }

        // Keep the main thread running
        RunLoop.current.run()
    }

    private func listenForInput() {
        while true {
            let char = getchar()

            DispatchQueue.main.async {
                switch Character(UnicodeScalar(UInt32(char))!) {
                case " ":
                    self.toggleTimer()
                case "r", "R":
                    self.resetTimer()
                case "q", "Q":
                    self.quit()
                case "+", "=":
                    self.increaseDuration()
                case "-", "_":
                    self.decreaseDuration()
                default:
                    break
                }
            }
        }
    }

    private func toggleTimer() {
        if timerManager.isRunning {
            timerManager.stop()
            print("\r⏸  Timer stopped         ")
        } else {
            timerManager.start()
            print("\r▶️  Timer started         ")
        }
    }

    private func resetTimer() {
        timerManager.reset()
        print("\r🔄 Timer reset           ")
    }

    private func quit() {
        setRawMode(false)
        print("\n\nGoodbye!")
        exit(0)
    }

    private func increaseDuration() {
        preferences.timerDuration += 60
        timerManager.reset()
        print("\r⏱  Duration: \(formatTime(preferences.timerDuration))     ")
    }

    private func decreaseDuration() {
        if preferences.timerDuration > 60 {
            preferences.timerDuration -= 60
            timerManager.reset()
            print("\r⏱  Duration: \(formatTime(preferences.timerDuration))     ")
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let absSeconds = abs(seconds)
        let minutes = absSeconds / 60
        let secs = absSeconds % 60
        let prefix = seconds < 0 ? "🔴 " : ""
        return String(format: "\(prefix)%02d:%02d", minutes, secs)
    }

    private func setRawMode(_ enable: Bool) {
        var term = termios()
        tcgetattr(STDIN_FILENO, &term)

        if enable {
            term.c_lflag &= ~UInt(ICANON | ECHO)
        } else {
            term.c_lflag |= UInt(ICANON | ECHO)
        }

        tcsetattr(STDIN_FILENO, TCSANOW, &term)
    }

    // MARK: - TimerManagerDelegate

    func timerDidComplete() {
        print("\r🔔 Timer complete!       ")
    }

    func timerDidUpdate(timeRemaining: Int) {
        print("\r⏱  \(formatTime(timeRemaining))  ", terminator: "")
        fflush(stdout)
    }
}
