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
                ForEach(viewModel.readings) { reading in
                    BarMark(
                        x: .value("time", reading.date),
                        y: .value(String(describing: reading.function), reading.doubleValue)
                    )
                }
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

    init(device: OwonDevice) {
        self.device = device
    }

    func observeDevice() async {
        for await notification in NotificationCenter.default.notifications(named: .owonDeviceDidReadNewMeasurement) {
            if Task.isCancelled { break }
            guard notification.device === self.device else { continue }
            readings.append(notification.reading!)
        }
    }
}

struct OwonView_Previews: PreviewProvider {
    static var previews: some View {
        OwonView()
    }
}
