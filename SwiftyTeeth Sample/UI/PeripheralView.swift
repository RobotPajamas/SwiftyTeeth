//
//  DeviceView.swift
//  SwiftyTeeth Sample
//
//  Created by SJ on 2020-03-27.
//

import SwiftyTeeth
import SwiftUI

final class PeripheralViewModel: ObservableObject {
    let peripheral: Device
    let serviceUuid = UUID(uuidString: "00726f62-6f74-7061-6a61-6d61732e6361")
    let txUuid = UUID(uuidString: "01726f62-6f74-7061-6a61-6d61732e6361")
    let rxUuid = UUID(uuidString: "02726f62-6f74-7061-6a61-6d61732e6361")

    @Published var logMessage = ""
    
    init(peripheral: Device) {
        self.peripheral = peripheral
    }
    
    private func log(_ text: String) {
        print(text)
        DispatchQueue.main.async {
            self.logMessage.append(text + "\n")
        }
    }
    
    func connect() {
        peripheral.connect { (isConnected) in
            guard isConnected == true else {
                self.log("Not connected")
                return
            }
            
            self.log("App: Device is connected? \(isConnected)")
            self.log("App: Starting service discovery...")
            
            self.peripheral.discoverServices { (result) in
                let services = result.value ?? []
                services.forEach { (service) in
                    self.log("App: Discovering characteristics for service: \(service.uuid.uuidString)")
                    self.peripheral.discoverCharacteristics(for: service) { (result) in
                        let characteristics = result.value?.characteristics ?? []
                        characteristics.forEach { (characteristuc) in
                            self.log("App: Discovered characteristic: \(characteristuc.uuid.uuidString) in \(String(describing: service.uuid.uuidString))")
                        }
                        
                        if service == services.last {
                            self.log("App: All services/characteristics discovered")
                        }
                    }
                }
            }
        }
    }
    
    func disconnect() {
        peripheral.disconnect()
    }
    
    func subscribe() {
        peripheral.subscribe(to: rxUuid!.uuidString, in: serviceUuid!.uuidString) { result in
            guard let value = result.value else {
                self.log("Subscribed value returned nil")
                return
            }
            self.log("Subscribed value: \([UInt8](value))")
        }
    }
    
    func read() {
        peripheral.read(from: rxUuid!.uuidString, in: serviceUuid!.uuidString) { (result) in
            guard let value = result.value else {
                self.log("Read returned nil")
                return
            }
            self.log("Read value: \([UInt8](value))")
        }
    }
    
    func write() {
        let command = Data([0x01])
        peripheral.write(data: command, to: txUuid!.uuidString, in: serviceUuid!.uuidString) { result in
            self.log("Write with response successful? \(result.isSuccess)")
        }
    }
}

struct PeripheralView: View {
    @ObservedObject var vm: PeripheralViewModel
    let peripheral: Device
    
    init(peripheral: Device) {
        self.peripheral = peripheral
        self.vm = PeripheralViewModel(peripheral: peripheral)
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Subscribe") {
                    self.vm.subscribe()
                }
                Spacer()
                Button("Read") {
                    self.vm.read()
                }
                Spacer()
                Button("Write") {
                    self.vm.write()
                }
                Spacer()
            }
            TextView(text: $vm.logMessage, autoscroll: true)
        }.onAppear {
            self.vm.connect()
        }.onDisappear {
            self.vm.disconnect()
        }.navigationBarTitle("Peripheral", displayMode: .inline)
    }
}
