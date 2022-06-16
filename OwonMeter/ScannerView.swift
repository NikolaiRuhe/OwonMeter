import SwiftUI
import OwonBLE
import Charts


struct OwonView: View {
    @StateObject var viewModel = ScannerViewModel()

    var body: some View {
        if let device = viewModel.discoveredDevice {
            DeviceView(device: device)
        } else {
            ScannerView(viewModel: viewModel)
        }
    }
}


struct DeviceView: View {
    @StateObject var viewModel: DeviceViewModel
    @State var xScale: Double = 25
    @State var xOffset: Double = 0

    init(device: OwonDevice) {
        _viewModel = StateObject(wrappedValue: DeviceViewModel(device: device))
    }

    var body: some View {
        VStack {
            if let reading = viewModel.reading {
                Text(verbatim: "\(reading)").font(.largeTitle.monospacedDigit())
            } else {
                Text("nil")
            }
            Chart {
                ForEach(viewModel.readings.dropLast(Int(xOffset)).suffix(Int(xScale))) { reading in
                    LineMark(
                        x: .value("time", reading.date),
                        y: .value(String(describing: reading.function), reading.doubleValue)
                    )
                    .symbol(by: .value("Category", "Voltage DC"))
                }
            }
            .chartYScale(domain: viewModel.range)
            .chartLegend(.hidden)
            HStack {
                Slider(value: $xScale, in: 20...500) {
                    Text("x scale")
                } minimumValueLabel: {
                    Text("20")
                } maximumValueLabel: {
                    Text("500")
                }
                Text("\(Int(xScale))")
            }
            HStack {
                Slider(value: $xOffset, in: 0...1000) {
                    Text("x offset")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("1000")
                }
                Text("\(Int(xScale))")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.observeDevice()
        }
    }
}


struct ScannerView: View {
    @ObservedObject var viewModel: ScannerViewModel

    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Scanning").fixedSize()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.scanAndConnect()
        }
    }
}

@MainActor
final class DeviceViewModel: ObservableObject {
    var device: OwonDevice

    var reading: Reading? { readings.last }

    @Published
    var readings: [Reading] = []

    @Published
    var range = -1.0 ... 1.0

    init(device: OwonDevice) {
        self.device = device
    }

    func observeDevice() async {
        for await notification in NotificationCenter.default.notifications(named: .owonDeviceDidReadNewMeasurement) {
            if Task.isCancelled { break }
            guard notification.device === self.device else { continue }
            let reading = notification.reading!
            readings.append(reading)
            let value = reading.doubleValue
            if range.contains(value) { continue }
            if range.lowerBound < value {
                range = range.lowerBound ... value
            } else {
                range = value ... range.upperBound
            }
        }
    }
}

struct OwonView_Previews: PreviewProvider {
    static var previews: some View {
        OwonView()
    }
}
