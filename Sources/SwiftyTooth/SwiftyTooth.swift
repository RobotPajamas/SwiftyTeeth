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

// MARK: - SwiftyTooth Advertise functions
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
    
    // MARK: - Peripheral Manager State Changes
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
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {

    }
    
    // MARK: - Peripheral Manager Services
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        
    }
    
    // MARK: - Peripheral Manager Advertisments
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        Log(v: "Started advertising")
        print("Started advertising")
    }
    
    // MARK: - Peripheral Manager Characteristic Subscriptions
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
    }
    
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        
    }
    
    // MARK: - Peripheral Manager Read/Write requests
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        request.value = Data(base64Encoded: "Hello")
        peripheralManager.respond(to: request, withResult: .success)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
//        peripheralManager.respond(to: <#T##CBATTRequest#>, withResult: <#T##CBATTError.Code#>)
    }
    
}
