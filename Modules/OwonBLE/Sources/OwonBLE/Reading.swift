import Foundation


/// One measurement, as read from OwonDevice.
public struct Reading: CustomStringConvertible {

    var scale: Scale
    var decimal: Int
    var function: Function
    var options: Options
    var value: Int

    init?(data: Data) {
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
    }

    public var description: String {
        if decimal >= 4 { return "Overload" }
        return "\(Double(value) / pow(10, Double(decimal))) \(scale)\(function)"
    }

    enum Scale: UInt16, CustomStringConvertible {
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

    enum Function: UInt16, CustomStringConvertible {
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

    struct Options: OptionSet {
        let rawValue: UInt16

        static let hold = Options(rawValue: 0x01)
        static let delta = Options(rawValue: 0x02)
        static let lowBattery = Options(rawValue: 0x08)
        static let min = Options(rawValue: 0x10)
        static let max = Options(rawValue: 0x20)
    }
}


extension Data {
    public subscript(uint16At index: Int) -> UInt16 {
        (UInt16(self[index * 2]) << 0) | (UInt16(self[index * 2 + 1]) << 8)
    }
}
