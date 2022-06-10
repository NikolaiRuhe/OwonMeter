import SwiftUI
import OwonBLE

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

    @Published
    var reading: Reading?

    init(device: OwonDevice) {
        self.device = device
    }

    func observeDevice() async {
        for await notification in NotificationCenter.default.notifications(named: .owonDeviceDidReadNewMeasurement) {
            if Task.isCancelled { break }
            guard notification.device === self.device else { continue }
            reading = notification.reading
        }
    }
}

struct OwonView_Previews: PreviewProvider {
    static var previews: some View {
        OwonView()
    }
}
