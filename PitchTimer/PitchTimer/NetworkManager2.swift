import Foundation
import Network

protocol NetworkManagerDelegate: AnyObject {
    func didReceiveTimerCommand(_ command: TimerCommand)
    func didUpdateConnectionStatus(_ status: ConnectionStatus)
}

enum TimerCommand: Codable {
    case start
    case stop
    case reset
    case setDuration(Int)
    case updateTime(Int, Bool) // timeRemaining, isRunning
    case setDisplayMode(DisplayMode)
}

enum ConnectionStatus {
    case disconnected
    case hosting(code: String)
    case connected(code: String, peerCount: Int)
}

class NetworkSyncManager {
    weak var delegate: NetworkManagerDelegate?

    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var discovery: NetworkDiscovery?
    private var udpDiscovery: UDPDiscovery?
    private var sessionCode: String?
    private var isHost = false
    private var currentPort: UInt16?
    private var syncTimer: Timer?

    private let basePort: UInt16 = 59000

    init() {
        self.discovery = NetworkDiscovery()
        self.udpDiscovery = UDPDiscovery()
    }

    // MARK: - Public Interface

    func startHosting() -> String {
        let code = generateCode()
        sessionCode = code
        isHost = true

        startListener(code: code)
        return code
    }

    func joinSession(code: String, completion: @escaping (Bool) -> Void) {
        sessionCode = code
        isHost = false

        // Use UDP discovery
        udpDiscovery?.onServiceDiscovered = { [weak self] host, port in
            guard let self = self else { return }
            print("Discovered service at \(host):\(port)")
            self.connectToHost(host: host, port: port, code: code)
            completion(true)
        }

        udpDiscovery?.startListening(forCode: code)

        // Timeout after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.connections.isEmpty ?? true {
                completion(false)
            }
        }
    }

    func disconnect() {
        listener?.cancel()
        listener = nil

        for conn in connections {
            conn.cancel()
        }
        connections.removeAll()

        discovery?.stopPublishing()
        discovery?.stopBrowsing()
        udpDiscovery?.stop()

        syncTimer?.invalidate()
        syncTimer = nil

        sessionCode = nil
        currentPort = nil
        isHost = false

        delegate?.didUpdateConnectionStatus(.disconnected)
    }

    // Start broadcasting time sync (host only)
    func startTimeSyncBroadcast(getTime: @escaping () -> (Int, Bool)) {
        guard isHost else { return }

        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            let (time, running) = getTime()
            self?.broadcast(.updateTime(time, running))
        }
    }

    // Stop broadcasting time sync
    func stopTimeSyncBroadcast() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    func broadcast(_ command: TimerCommand) {
        guard let data = try? JSONEncoder().encode(command) else { return }

        for connection in connections {
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("Broadcast error: \(error)")
                }
            })
        }
    }

    // MARK: - Private Methods

    private func generateCode() -> String {
        let digits = "0123456789"
        return String((0..<6).map { _ in digits.randomElement()! })
    }

    private func startListener(code: String) {
        let port = basePort + UInt16.random(in: 0..<1000)

        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true

            let listener = try NWListener(using: params, on: NWEndpoint.Port(integerLiteral: port))

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }

            listener.stateUpdateHandler = { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .ready:
                    print("Listener ready on port \(port)")
                    self.currentPort = port

                    // Start both Bonjour and UDP broadcasting
                    self.discovery?.startPublishing(withCode: code, port: Int(port))
                    self.udpDiscovery?.startBroadcasting(code: code, tcpPort: port)

                    DispatchQueue.main.async {
                        self.delegate?.didUpdateConnectionStatus(.hosting(code: code))
                    }
                case .failed(let error):
                    print("Listener failed: \(error)")
                default:
                    break
                }
            }

            listener.start(queue: .main)
            self.listener = listener

        } catch {
            print("Failed to create listener: \(error)")
        }
    }

    private func connectToHost(host: String, port: UInt16, code: String) {
        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: port),
            using: .tcp
        )

        setupConnection(connection, code: code)
        connection.start(queue: .main)
    }

    private func handleIncomingConnection(_ connection: NWConnection) {
        setupConnection(connection, code: sessionCode ?? "")
        connection.start(queue: .main)
    }

    private func setupConnection(_ connection: NWConnection, code: String) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .ready:
                self.connections.append(connection)
                self.startReceiving(on: connection)

                DispatchQueue.main.async {
                    if self.isHost {
                        self.delegate?.didUpdateConnectionStatus(.hosting(code: code))
                    } else {
                        self.delegate?.didUpdateConnectionStatus(.connected(code: code, peerCount: 1))
                    }
                }

            case .failed(let error):
                print("Connection failed: \(error)")
                self.removeConnection(connection)

            case .cancelled:
                self.removeConnection(connection)

            default:
                break
            }
        }
    }

    private func startReceiving(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }

            if let data = data, !data.isEmpty {
                if let command = try? JSONDecoder().decode(TimerCommand.self, from: data) {
                    DispatchQueue.main.async {
                        self.delegate?.didReceiveTimerCommand(command)
                    }
                }
            }

            if let error = error {
                print("Receive error: \(error)")
                return
            }

            if !isComplete {
                self.startReceiving(on: connection)
            }
        }
    }

    private func removeConnection(_ connection: NWConnection) {
        connections.removeAll { $0 === connection }

        if let code = sessionCode {
            DispatchQueue.main.async {
                if self.isHost {
                    self.delegate?.didUpdateConnectionStatus(.hosting(code: code))
                } else if self.connections.isEmpty {
                    self.delegate?.didUpdateConnectionStatus(.disconnected)
                } else {
                    self.delegate?.didUpdateConnectionStatus(.connected(code: code, peerCount: self.connections.count))
                }
            }
        }
    }
}
