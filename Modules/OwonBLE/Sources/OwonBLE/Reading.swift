import Foundation


/// One measurement, as read from OwonDevice.
public struct Reading: CustomStringConvertible, Identifiable {

    static var runningID: Int = 0
    static func nextID() -> Int {
        defer { runningID += 1 }
        return runningID
    }

    public var scale: Scale
    public var decimal: Int
    public var function: Function
    public var options: Options
    public var value: Int
    public var date: Date
    public var id: Int = Self.nextID()

    init?(data: Data, date: Date = Date()) {
        guard data.count == 6 else { return nil }
        let firstWord = data[uint16At: 0]
        guard let scale = Scale(rawValue: (firstWord >> 3) & 0x07) else { return nil }
        guard let function = Function(rawValue: (firstWord >> 6) & 0x0f) else { return nil }

        self.options = Options(rawValue: data[uint16At: 1])
        self.decimal = Int(firstWord & 0x07)
        self.scale = scale
        self.function = function

        let valueWord = data[uint16At: 2]
        let negative = valueWord >= 0x8000
        self.value = Int(valueWord & 0x7fff) * (negative ? -1 : 1)
        self.date = date
    }

    public var doubleValue: Double { Double(value) / pow(10, Double(decimal)) }

    public var description: String {
        if decimal >= 4 { return "Overload" }
        return "\(Double(value) / pow(10, Double(decimal))) \(scale)\(function)"
    }

    public enum Scale: UInt16, CustomStringConvertible {
        case pico = 0
        case nano = 1
        case micro = 2
        case milli = 3
        case one = 4
        case kilo = 5
        case mega = 6
        case giga = 7

        public var description: String {
            switch self {

            case .pico:  return "p"
            case .nano:  return "n"
            case .micro: return "µ"
            case .milli: return "m"
            case .one:   return ""
            case .kilo:  return "k"
            case .mega:  return "M"
            case .giga:  return "G"
            }
        }
    }

    public enum Function: UInt16, CustomStringConvertible {
        case voltageDC = 0
        case voltageAC = 1
        case amperesDC = 2
        case amperesAC = 3
        case ohms = 4
        case farad = 5
        case hz = 6
        case percent = 7
        case degCelcius = 8
        case degFarenheit = 9
        case v = 10
        case ohms2 = 11
        case hFE = 12

        public var description: String {
            switch self {

            case .voltageDC:    return "V(DC)"
            case .voltageAC:    return "V(AC)"
            case .amperesDC:    return "A(DC)"
            case .amperesAC:    return "A(AC)"
            case .ohms:         return "Ω"
            case .farad:        return "F"
            case .hz:           return "Hz"
            case .percent:      return "%"
            case .degCelcius:   return "°C"
            case .degFarenheit: return "°F"
            case .v:            return "V"
            case .ohms2:        return "Ω"
            case .hFE:          return "hFE"
            }
        }
    }

    public struct Options: OptionSet {
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        public let rawValue: UInt16

        public static let hold = Options(rawValue: 0x01)
        public static let delta = Options(rawValue: 0x02)
        public static let lowBattery = Options(rawValue: 0x08)
        public static let min = Options(rawValue: 0x10)
        public static let max = Options(rawValue: 0x20)
    }
}


extension Data {
    public subscript(uint16At index: Int) -> UInt16 {
        (UInt16(self[index * 2]) << 0) | (UInt16(self[index * 2 + 1]) << 8)
    }
}
