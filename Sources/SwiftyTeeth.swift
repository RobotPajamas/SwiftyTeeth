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

    static let shared = SwiftyTeeth()

    fileprivate var scanChangesHandler: ((Device) -> Void)?
    fileprivate var scanCompleteHandler: (([Device]) -> Void)?

    fileprivate lazy var centralManager: CBCentralManager = {
        let instance = CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.robotpajamas.SwiftyTeeth"))
        // Throwaway command to init CoreBluetooth (helps prevent timing problems)
        instance.retrievePeripherals(withIdentifiers: [])
        return instance
    }()

    
    // TODO: Need iOS 9 support
//    open var state: CBManagerState {
//        return centralManager.state
//    }

    open var isScanning: Bool {
        return centralManager.isScanning
    }

    // TODO: Hold a private set, and expose a list?
    open var scannedPeripherals = Set<Device>()
    
    // TODO: Should be a list? Can connect to > 1 device
    open var device: Device?
    
    public override init() {
    }
}

// MARK: - Manager functions
extension SwiftyTeeth {

    open func scan() {
        scannedPeripherals.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    open func scan(changes: ((Device) -> Void)?) {
        scanChangesHandler = changes
        scan()
    }
    
    open func scan(for timeout: TimeInterval = 10, changes: ((Device) -> Void)? = nil, complete: @escaping ([Device]) -> Void) {
        scanChangesHandler = changes
        scanCompleteHandler = complete
        // TODO: Should this be on main, or on CB queue?
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            self.stopScan()
        }
        scan()
    }

    open func stopScan() {
        // TODO: Cancel asyncAfter if in progress?
        centralManager.stopScan()
        scanCompleteHandler?(Array(scannedPeripherals))
        
        // Reset Handlers
        scanChangesHandler = nil
        scanCompleteHandler = nil
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
        let device = Device(peripheral: peripheral)
        scannedPeripherals.insert(device)
        scanChangesHandler?(device)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        device = Device(peripheral: peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    
    }
}
