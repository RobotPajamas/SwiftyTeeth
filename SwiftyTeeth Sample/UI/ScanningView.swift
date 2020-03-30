//
//  ScanningView.swift
//  SwiftyTeeth Sample
//
//  Created by SJ on 2020-03-27.
//

import SwiftUI
import SwiftyTeeth

final class ScanningViewModel: ObservableObject, SwiftyTeethable {
    @Published var isScanning = false
    @Published var peripherals = [Device]()
    
    init() {
        swiftyTeeth.stateChangedHandler = { (state) in
            print("Bluetooth State is: \(state)")
        }
    }
    
    func scan(timeout: Int = 5) {
        print("Starting scan for nearby peripherals with timeout: \(timeout)")
        isScanning = true
        swiftyTeeth.scan(for: TimeInterval(timeout)) { (peripherals) in
            self.isScanning = false
            print("Discovered \(peripherals.count) nearby peripherals")
            self.peripherals = peripherals
        }
    }
}

struct PeripheralRow: View {
    let name: String
    var body: some View {
        HStack {
            Text("\(name)")
            Spacer()
        }
    }
}
struct ScanningView: View {
    @ObservedObject var vm = ScanningViewModel()
    
    private var scanButton: some View {
        Button("Scan") {
            self.vm.scan(timeout: 3)
        }.disabled(vm.isScanning == true)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.vm.peripherals) { peripheral in
                    NavigationLink(destination: PeripheralView(peripheral: peripheral)) {
                        PeripheralRow(name: peripheral.name)
                    }
                    
                }
            }.listStyle(GroupedListStyle())
            .navigationBarTitle("Scanning", displayMode: .inline)
            .navigationBarItems(trailing: scanButton)
        }
    }
}

struct ScanningView_Previews: PreviewProvider {
    static var previews: some View {
        ScanningView()
    }
}
