import Foundation
import Network

class UDPDiscovery {
    private var listener: NWListener?
    private var connection: NWConnection?
    private let broadcastPort: UInt16 = 59100

    var onServiceDiscovered: ((String, UInt16) -> Void)?

    // Start broadcasting session info
    func startBroadcasting(code: String, tcpPort: UInt16) {
        // Broadcast UDP packets with session info
        let message = "\(code):\(tcpPort)"
        guard let data = message.data(using: .utf8) else { return }

        // Create UDP connection for broadcasting
        let host = NWEndpoint.Host("255.255.255.255") // Broadcast address
        let port = NWEndpoint.Port(integerLiteral: broadcastPort)

        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true

        let broadcastConnection = NWConnection(host: host, port: port, using: parameters)
        self.connection = broadcastConnection

        broadcastConnection.stateUpdateHandler = { state in
            if case .ready = state {
                // Send broadcast every 2 seconds
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self, weak broadcastConnection] _ in
                    guard let connection = broadcastConnection else { return }
                    connection.send(content: data, completion: .idempotent)
                }
            }
        }

        broadcastConnection.start(queue: .main)
    }

    // Listen for broadcasts
    func startListening(forCode code: String) {
        do {
            let parameters = NWParameters.udp
            parameters.allowLocalEndpointReuse = true
            parameters.acceptLocalOnly = true

            let listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: broadcastPort))
            self.listener = listener

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingBroadcast(connection, targetCode: code)
            }

            listener.stateUpdateHandler = { state in
                print("UDP Listener state: \(state)")
            }

            listener.start(queue: .main)
        } catch {
            print("Failed to create UDP listener: \(error)")
        }
    }

    private func handleIncomingBroadcast(_ connection: NWConnection, targetCode: String) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            guard let data = data,
                  let message = String(data: data, encoding: .utf8) else { return }

            let parts = message.split(separator: ":")
            if parts.count == 2,
               let code = parts.first,
               let portString = parts.last,
               let port = UInt16(portString),
               code == targetCode {

                // Extract sender's IP address
                if let endpoint = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, _) = endpoint {
                    DispatchQueue.main.async {
                        self?.onServiceDiscovered?(String(describing: host), port)
                    }
                }
            }
        }

        connection.start(queue: .main)
    }

    func stop() {
        listener?.cancel()
        connection?.cancel()
        listener = nil
        connection = nil
    }
}
