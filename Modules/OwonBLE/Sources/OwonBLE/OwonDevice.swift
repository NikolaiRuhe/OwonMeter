import Foundation
import CoreBluetooth


public class OwonDevice {
    fileprivate let peripheral: CBPeripheral
    fileprivate let commandCharacteristic: CBCharacteristic
    fileprivate let controlCharacteristic: CBCharacteristic
    fileprivate let measurementCharacteristic: CBCharacteristic
    fileprivate lazy var peripheralDelegate = { PeripheralDelegate(self) }()

    public static var all: [OwonDevice] = []

    init?(from peripheral: CBPeripheral) {
        guard let service = peripheral.services?.first(where: { $0.uuid == .owonService }) else { return nil }
        guard let commandCharacteristic = service.characteristics?.first(where: { $0.uuid == .owonCommandCharacteristic }) else { return nil }
        guard let controlCharacteristic = service.characteristics?.first(where: { $0.uuid == .owonControlCharacteristic }) else { return nil }
        guard let measurementCharacteristic = service.characteristics?.first(where: { $0.uuid == .owonMeasurementCharacteristic }) else { return nil }

        self.peripheral = peripheral
        self.commandCharacteristic = commandCharacteristic
        self.controlCharacteristic = controlCharacteristic
        self.measurementCharacteristic = measurementCharacteristic

        peripheral.delegate = self.peripheralDelegate
        peripheral.setNotifyValue(true, for: measurementCharacteristic)
        peripheral.readValue(for: measurementCharacteristic)
    }
}


fileprivate extension OwonDevice {

    final class PeripheralDelegate: NSObject, CBPeripheralDelegate {
        weak var device: OwonDevice?
        init(_ device: OwonDevice) { self.device = device }

        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            guard let data = characteristic.value else { return }
            guard let reading = Reading(data: data) else {
                print("measurement error")
                return
            }
            print("value: \(reading)")
            NotificationCenter.default.post(name: .owonDeviceDidReadNewMeasurement, object: self, userInfo: ["device": device, "reading": reading])
        }
    }
}


public extension Notification.Name {
    static let owonDeviceDidReadNewMeasurement = Notification.Name("owonDeviceDidReadNewMeasurement")
}

public extension Notification {
    var device: OwonDevice? {
        userInfo?["device"] as? OwonDevice
    }
    var reading: Reading? {
        userInfo?["reading"] as? Reading
    }
}


fileprivate extension CBUUID {
    static let owonCommandCharacteristic = CBUUID(string: "FFF1")
    static let owonControlCharacteristic = CBUUID(string: "FFF3")
    static let owonMeasurementCharacteristic = CBUUID(string: "FFF4")
}
