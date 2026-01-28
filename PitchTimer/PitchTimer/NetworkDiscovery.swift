import Foundation

class NetworkDiscovery: NSObject {
    private var browser: NetServiceBrowser?
    private var publisher: NetService?
    private var discoveredServices: [String: NetService] = [:]

    var onServiceFound: ((String, NetService) -> Void)?
    var onServiceLost: ((String) -> Void)?

    func startPublishing(withCode code: String, port: Int) {
        let serviceName = "PitchTimer-\(code)"
        publisher = NetService(domain: "local.", type: "_pitchtimer._tcp.", name: serviceName, port: Int32(port))
        publisher?.delegate = self
        publisher?.publish()
    }

    func startBrowsing() {
        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(ofType: "_pitchtimer._tcp.", inDomain: "local.")
    }

    func stopPublishing() {
        publisher?.stop()
        publisher = nil
    }

    func stopBrowsing() {
        browser?.stop()
        browser = nil
        discoveredServices.removeAll()
    }

    func resolveService(forCode code: String, completion: @escaping (String?, Int?) -> Void) {
        let serviceName = "PitchTimer-\(code)"

        if let service = discoveredServices[serviceName] {
            service.resolve(withTimeout: 5.0)

            // Wait for resolution
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if let addresses = service.addresses, !addresses.isEmpty {
                    let address = self.getAddress(from: addresses[0])
                    completion(address, service.port)
                } else {
                    completion(nil, nil)
                }
            }
        } else {
            completion(nil, nil)
        }
    }

    private func getAddress(from data: Data) -> String? {
        data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> String? in
            guard let sockaddr = pointer.baseAddress?.assumingMemoryBound(to: sockaddr.self) else {
                return nil
            }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

            if getnameinfo(sockaddr, socklen_t(data.count),
                          &hostname, socklen_t(hostname.count),
                          nil, 0, NI_NUMERICHOST) == 0 {
                return String(cString: hostname)
            }

            return nil
        }
    }
}

extension NetworkDiscovery: NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
        print("Published service: \(sender.name)")
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        print("Failed to publish service: \(errorDict)")
    }
}

extension NetworkDiscovery: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Found service: \(service.name)")
        discoveredServices[service.name] = service
        service.delegate = self

        if let code = service.name.components(separatedBy: "-").last {
            onServiceFound?(code, service)
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("Lost service: \(service.name)")
        discoveredServices.removeValue(forKey: service.name)

        if let code = service.name.components(separatedBy: "-").last {
            onServiceLost?(code)
        }
    }
}
