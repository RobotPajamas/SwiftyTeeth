//
//  SwiftyTooth.swift
//  SwiftyTeeth
//
//  Created by Suresh Joshi on 2019-11-23.
//

import Foundation
import CoreBluetooth

var swiftyToothLogger: Logger?

open class SwiftyTooth: NSObject {

    public static let shared = SwiftyTooth()
    
    public var stateChangedHandler: ((BluetoothState) -> Void)? {
        didSet {
            stateChangedHandler?(state)
        }
    }

    open lazy var peripheralManager: CBPeripheralManager = {
        let instance = CBPeripheralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.robotpajamas.SwiftyTooth"))
        // Throwaway command to init CoreBluetooth (helps prevent timing problems)
        return instance
    }()

    public var state: BluetoothState {
        return BluetoothState(rawValue: peripheralManager.state.rawValue) ?? .unknown
    }
    
    public override init() {
    }
}

public extension SwiftyTooth {
    class var logger: Logger? {
        get {
            return swiftyToothLogger
        }
        set {
            swiftyToothLogger = newValue
        }
    }
}

// MARK: - Manager Advertise functions
public extension SwiftyTooth {

    var isAdvertising: Bool {
        return peripheralManager.isAdvertising
    }
    
    func advertise(name: String, uuids: [CBUUID] = [], for timeout: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            self.stopAdvertising()
        }
        advertise(name: name)
    }
    
    func advertise(name: String, uuids: [CBUUID] = []) {
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey:name,
            CBAdvertisementDataServiceUUIDsKey: uuids
        ])
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
    }
}

// MARK: - Peripheral manager
extension SwiftyTooth: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch (peripheral.state) {
        case .unknown:
            Log(v: "Bluetooth state is unknown.")
        case .resetting:
            Log(v: "Bluetooth state is resetting.")
        case .unsupported:
            Log(v: "Bluetooth state is unsupported.")
        case .unauthorized:
            Log(v: "Bluetooth state is unauthorized.")
        case .poweredOff:
            Log(v: "Bluetooth state is powered off.")
        case .poweredOn:
            Log(v: "Bluetooth state is powered on")
        default:
            Log(v: "Bluetooth state is not in supported switches")
        }
        
        guard let state = BluetoothState(rawValue: peripheral.state.rawValue) else {
            return
        }
        stateChangedHandler?(state)
    }
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        Log(v: "Started advertising")
        print("Started advertising")
    }
}
