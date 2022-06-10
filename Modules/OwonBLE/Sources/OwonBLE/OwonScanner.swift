import Foundation
import CoreBluetooth


/// `OwonScanner` is used to detect Owon Multimeter BLE devices.
///
/// It scans for available BLE devices and tries to connect to unidentified
/// devices. After connecting it looks for the owon service id fff0. For each
/// detected Owon B35 device it creates an `OwonDevice` instance.
///
/// Usage:
///
///     let scanner = OwonScanner()
///     scanner.isActive = true
public final class OwonScanner {

    public static let shared = OwonScanner()

    lazy var centralManager: CBCentralManager = { CBCentralManager(delegate: centralManagerDelegate, queue: nil) }()
    fileprivate lazy var centralManagerDelegate: BluetoothDelegate = BluetoothDelegate(self)
    public var isActive = false { didSet { update() } }
    fileprivate var examinedPeripherals: [CBPeripheral] = []

    deinit {
        centralManager.delegate = nil
        examinedPeripherals
            .filter { $0.delegate === centralManagerDelegate }
            .forEach { $0.delegate = nil }
    }

    func update() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: [], options: nil)
        print("start scanning for peripherals")
    }
}


fileprivate extension OwonScanner {
    final class BluetoothDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
        weak var scanner: OwonScanner?
        init(_ scanner: OwonScanner) { self.scanner = scanner }

        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            scanner?.update()
        }

        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            guard let scanner = scanner else { return }
            guard !scanner.examinedPeripherals.contains(peripheral) else { return }
            print("did discover peripheral: \(peripheral)")

            peripheral.delegate = scanner.centralManagerDelegate
            scanner.examinedPeripherals.append(peripheral)
            scanner.centralManager.connect(peripheral, options: nil)
        }

        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            guard scanner != nil else { return }
            print("did connect peripheral: \(peripheral)")
            peripheral.discoverServices(nil)
        }

        func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            print("did fail to connect peripheral: \(peripheral)")
            if peripheral.delegate === scanner?.centralManagerDelegate {
                peripheral.delegate = nil
            }
        }

        func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            print("did disconnect peripheral: \(peripheral)")
            if peripheral.delegate === scanner?.centralManagerDelegate {
                peripheral.delegate = nil
            }
        }

        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            guard let service = peripheral.services?.first(where: { $0.uuid == .owonService }) else {
                peripheral.delegate = nil
                scanner?.centralManager.cancelPeripheralConnection(peripheral)
                return
            }
            peripheral.discoverCharacteristics(nil, for: service)
        }

        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            guard let device = OwonDevice(from: peripheral) else {
                peripheral.delegate = nil
                scanner?.centralManager.cancelPeripheralConnection(peripheral)
                return
            }

            print("did discover owon multimeter")
            OwonDevice.all.append(device)
            if let index = scanner?.examinedPeripherals.firstIndex(where: {$0 === peripheral}) {
                scanner?.examinedPeripherals.remove(at: index)
            }
            NotificationCenter.default.post(name: .didDiscoverOwonDevice, object: self, userInfo: ["device": device])
        }
    }
}


public extension Notification.Name {
    static let didDiscoverOwonDevice = Notification.Name("didDiscoverOwonDevice")
}


extension CBUUID {
    static let owonService = CBUUID(string: "FFF0")
}

