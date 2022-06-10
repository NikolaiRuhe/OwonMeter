import Foundation
import Combine
import OwonBLE

@MainActor
final class ScannerViewModel: ObservableObject {

    @Published
    var isScanning: Bool = false { didSet { OwonScanner.shared.isActive = isScanning } }

    @Published
    var discoveredDevice: OwonDevice? = nil

    func scanAndConnect() async {
        isScanning = true
        let iterator = NotificationCenter.default.notifications(named: .didDiscoverOwonDevice).makeAsyncIterator()
        let notification = await iterator.next()!
        discoveredDevice = notification.userInfo?["device"] as? OwonDevice
        isScanning = false
    }
}
