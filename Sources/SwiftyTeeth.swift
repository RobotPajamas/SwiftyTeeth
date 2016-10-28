//
//  SwiftyTeeth.swift
//  SwiftyTeeth
//
//  Created by Basem Emara on 10/27/16.
//
//

import Foundation
import CoreBluetooth

open class SwiftyTeeth: NSObject {

    static var shared: SwiftyTeeth {
        return SwiftyTeeth()
    }

    fileprivate lazy var centralManager: CBCentralManager = {
        return CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.robotpajamas.SwiftyTeeth"))
    }()

    open var state: CBManagerState {
        return centralManager.state
    }

    open var isScanning: Bool {
        return centralManager.isScanning
    }
    
    open var device: Device?
    
    public override init() {
        
    }
}

// MARK: - Manager functions
extension SwiftyTeeth {

    open func scan(with timeout: TimeInterval = 10, complete: ([CBPeripheral]) -> Void) {
        complete([]) //TODO
    }

    open func stopScan() {
        centralManager.stopScan()
    }

    open func connect(to peripheral: CBPeripheral, complete: (Device?) -> Void) {
        complete(nil) //TODO
    }

    open func disconnect(from peripheral: CBPeripheral, complete: () -> Void) {
        complete() //TODO
    }
}

// MARK: - Peripheral functions
extension SwiftyTeeth {

    open func readValue(for characteristic: UUID, complete: (CBCharacteristic) -> Void) {
        //TODO
    }

    open func write(data: NSData, for characteristic: UUID, complete: (CBCharacteristic) -> Void) {
        //TODO
    }
}

// MARK: - Central manager
extension SwiftyTeeth: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .unknown:
            print("Bluetooth state is unknown.")
        case .resetting:
            print("Bluetooth state is resetting.")
        case .unsupported:
            print("Bluetooth state is unsupported.")
        case .unauthorized:
            print("Bluetooth state is unauthorized.")
        case .poweredOff:
            print("Bluetooth state is powered off.")
        case .poweredOn:
            print("Bluetooth state is powered on")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral.name ?? "")
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        device = Device(delegate: self, peripheral: peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    
    }
}

// MARK: - Central peripheral
extension SwiftyTeeth: CBPeripheralDelegate {

    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    
    }
    
    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
    
    }
}
