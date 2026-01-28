import AppKit

class NetworkViewController: NSViewController {
    private var codeLabel: NSTextField!
    private var codeInput: NSTextField!
    private var hostButton: NSButton!
    private var joinButton: NSButton!
    private var disconnectButton: NSButton!
    private var statusLabel: NSTextField!
    private var containerView: NSView!

    var onHost: (() -> String)?
    var onJoin: ((String, @escaping (Bool) -> Void) -> Void)?
    var onDisconnect: (() -> Void)?

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 350))
        setupUI()
    }

    private func setupUI() {
        // Container
        containerView = NSView(frame: view.bounds)
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        view.addSubview(containerView)

        // Title
        let title = NSTextField(labelWithString: "Network Sync")
        title.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        title.frame = NSRect(x: 20, y: 300, width: 360, height: 30)
        title.alignment = .center
        containerView.addSubview(title)

        // Status
        statusLabel = NSTextField(labelWithString: "Not connected")
        statusLabel.font = NSFont.systemFont(ofSize: 13)
        statusLabel.frame = NSRect(x: 20, y: 270, width: 360, height: 20)
        statusLabel.alignment = .center
        statusLabel.textColor = .secondaryLabelColor
        containerView.addSubview(statusLabel)

        // Host section
        let hostLabel = NSTextField(labelWithString: "Host a Session")
        hostLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        hostLabel.frame = NSRect(x: 20, y: 230, width: 360, height: 20)
        containerView.addSubview(hostLabel)

        hostButton = NSButton(frame: NSRect(x: 150, y: 195, width: 100, height: 32))
        hostButton.title = "Start Hosting"
        hostButton.bezelStyle = .rounded
        hostButton.target = self
        hostButton.action = #selector(hostButtonClicked)
        containerView.addSubview(hostButton)

        codeLabel = NSTextField(labelWithString: "")
        codeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        codeLabel.frame = NSRect(x: 20, y: 160, width: 360, height: 30)
        codeLabel.alignment = .center
        codeLabel.textColor = .systemBlue
        containerView.addSubview(codeLabel)

        // Join section
        let joinLabel = NSTextField(labelWithString: "Join a Session")
        joinLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        joinLabel.frame = NSRect(x: 20, y: 120, width: 360, height: 20)
        containerView.addSubview(joinLabel)

        codeInput = NSTextField(frame: NSRect(x: 100, y: 90, width: 100, height: 24))
        codeInput.placeholderString = "Enter code"
        codeInput.alignment = .center
        codeInput.font = NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        containerView.addSubview(codeInput)

        joinButton = NSButton(frame: NSRect(x: 210, y: 87, width: 80, height: 28))
        joinButton.title = "Join"
        joinButton.bezelStyle = .rounded
        joinButton.target = self
        joinButton.action = #selector(joinButtonClicked)
        containerView.addSubview(joinButton)

        // Disconnect button
        disconnectButton = NSButton(frame: NSRect(x: 150, y: 50, width: 100, height: 32))
        disconnectButton.title = "Disconnect"
        disconnectButton.bezelStyle = .rounded
        disconnectButton.target = self
        disconnectButton.action = #selector(disconnectButtonClicked)
        disconnectButton.isHidden = true
        containerView.addSubview(disconnectButton)
    }

    @objc private func hostButtonClicked() {
        guard let code = onHost?() else { return }

        codeLabel.stringValue = code
        hostButton.isEnabled = false
        joinButton.isEnabled = false
        codeInput.isEnabled = false
        disconnectButton.isHidden = false
    }

    @objc private func joinButtonClicked() {
        let code = codeInput.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }

        statusLabel.stringValue = "Connecting..."

        onJoin?(code) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.hostButton.isEnabled = false
                    self?.joinButton.isEnabled = false
                    self?.codeInput.isEnabled = false
                    self?.disconnectButton.isHidden = false
                    self?.statusLabel.stringValue = "Connected to \(code)"
                } else {
                    self?.statusLabel.stringValue = "Failed to connect"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.statusLabel.stringValue = "Not connected"
                    }
                }
            }
        }
    }

    @objc private func disconnectButtonClicked() {
        onDisconnect?()

        codeLabel.stringValue = ""
        statusLabel.stringValue = "Disconnected"
        hostButton.isEnabled = true
        joinButton.isEnabled = true
        codeInput.isEnabled = true
        codeInput.stringValue = ""
        disconnectButton.isHidden = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.statusLabel.stringValue = "Not connected"
        }
    }

    func updateStatus(_ status: ConnectionStatus) {
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .disconnected:
                self?.statusLabel.stringValue = "Not connected"
                self?.codeLabel.stringValue = ""

            case .hosting(let code):
                self?.statusLabel.stringValue = "Hosting session"
                self?.codeLabel.stringValue = code

            case .connected(let code, let peerCount):
                self?.statusLabel.stringValue = "Connected to \(code) (\(peerCount) peer\(peerCount == 1 ? "" : "s"))"
            }
        }
    }
}
