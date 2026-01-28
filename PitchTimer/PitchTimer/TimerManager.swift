import Foundation

protocol TimerManagerDelegate: AnyObject {
    func timerDidComplete()
    func timerDidUpdate(timeRemaining: Int)
}

class TimerManager {
    weak var delegate: TimerManagerDelegate?
    private let preferences: Preferences
    private var timer: Timer?
    private var timeRemaining: Int = 0
    private var completionTriggered = false

    var isRunning: Bool {
        return timer != nil
    }

    var currentTime: Int {
        return timeRemaining
    }

    init(preferences: Preferences) {
        self.preferences = preferences
        self.timeRemaining = preferences.timerDuration
    }

    func start() {
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        stop()
        timeRemaining = preferences.timerDuration
        completionTriggered = false
        delegate?.timerDidUpdate(timeRemaining: timeRemaining)
    }

    // Set time directly (for network sync)
    func setTime(_ time: Int, isRunning: Bool) {
        timeRemaining = time
        delegate?.timerDidUpdate(timeRemaining: timeRemaining)

        // Trigger completion if crossing zero
        if time == 0 && !completionTriggered {
            completionTriggered = true
            delegate?.timerDidComplete()
        } else if time > 0 {
            completionTriggered = false
        }

        // Sync running state
        if isRunning && timer == nil {
            start()
        } else if !isRunning && timer != nil {
            stop()
        }
    }

    private func tick() {
        timeRemaining -= 1
        delegate?.timerDidUpdate(timeRemaining: timeRemaining)

        if timeRemaining == 0 && !completionTriggered {
            // Trigger completion alert but keep running
            completionTriggered = true
            delegate?.timerDidComplete()
        }
    }
}
