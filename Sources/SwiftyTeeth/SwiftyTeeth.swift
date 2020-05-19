//
//  SwiftyTeeth.swift
//  SwiftyTeeth
//
//  Created by Basem Emara on 10/27/16.
//
//

import Foundation
import CoreBluetooth

var swiftyTeethLogger: Logger?

open class SwiftyTeeth: NSObject {

    public static let shared = SwiftyTeeth()
    
    public var stateChangedHandler: ((BluetoothState) -> Void)? {
        didSet {
            stateChangedHandler?(state)
        }
    }

    public lazy var centralManager: CBCentralManager = {
        let instance = CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.robotpajamas.SwiftyTeeth"))
        return instance
    }()

    public var state: BluetoothState {
        return BluetoothState(rawValue: centralManager.state.rawValue) ?? .unknown
    }
    
    // TODO: Hold a private set, and expose a list?
    public var scannedDevices = Set<Device>()

    public var isScanning: Bool {
        return centralManager.isScanning
    }

    // TODO: Should be a list? Can connect to > 1 device
    private var connectedDevices = [String:Device]()
    private var scanChangesHandler: ((Device) -> Void)?
    private var scanCompleteHandler: (([Device]) -> Void)?
    
    public override init() {
    }
}

public extension SwiftyTeeth {
    class var logger: Logger? {
        get {
            return swiftyTeethLogger
        }
        set {
            swiftyTeethLogger = newValue
        }
    }
}

// MARK: - Manager Utility functions
public extension SwiftyTeeth {
    func retrievePeripherals(withIdentifiers uuids: [UUID]) -> [Device] {
        let cbPeripherals = centralManager.retrievePeripherals(withIdentifiers: uuids)
        return cbPeripherals.map { Device(manager: self, peripheral: $0) }
    }
}

// MARK: - Manager Scan functions
public extension SwiftyTeeth {

    func scan() {
        scannedDevices.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func scan(changes: ((Device) -> Void)?) {
        scanChangesHandler = changes
        scan()
    }
    
    func scan(for timeout: TimeInterval = 10, changes: ((Device) -> Void)? = nil, complete: @escaping ([Device]) -> Void) {
        scanChangesHandler = changes
        scanCompleteHandler = complete
        // TODO: Should this be on main, or on CB queue?
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            self.stopScan()
        }
        scan()
    }

    func stopScan() {
        // TODO: Cancel asyncAfter if in progress?
        centralManager.stopScan()
        scanCompleteHandler?(Array(scannedDevices))
        
        // Reset Handlers
        scanChangesHandler = nil
        scanCompleteHandler = nil
    }
}


// MARK: - Internal Connection functions
extension SwiftyTeeth {
    
    // Using these internal functions, so that we can track devices 'in use'
    func connect(to device: Device) {
        // Add device to dictionary only if it isn't there
//        if connectedDevices[device.id] == nil {
            connectedDevices[device.id] = device
//        }
        Log(v: "Connecting to device - \(device.id)")
        centralManager.connect(device.peripheral, options: nil)
    }
    
    // Using these internal functions, so that we can track devices 'in use'
    func disconnect(from device: Device) {
        // Add device to dictionary only if it isn't there
//        if connectedDevices[device.id] == nil {
            connectedDevices[device.id] = device
//        }
        Log(v: "Disconnecting from device - \(device.id)")
        centralManager.cancelPeripheralConnection(device.peripheral)
    }
}


// MARK: - Central manager
extension SwiftyTeeth: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
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
            // Throwaway command to init CoreBluetooth (helps prevent timing problems)
            centralManager.retrievePeripherals(withIdentifiers: [])
        default:
            Log(v: "Bluetooth state is not in supported switches")
        }
        
        guard let state = BluetoothState(rawValue: central.state.rawValue) else {
            return
        }
        stateChangedHandler?(state)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.name != nil else {
            return
        }
        
        let device = Device(manager: self, peripheral: peripheral)
        scannedDevices.insert(device)
        scanChangesHandler?(device)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Log(v: "centralManager: didConnect to \(peripheral.identifier) with maximum write value of \(peripheral.maximumWriteValueLength(for: .withoutResponse)) and \(peripheral.maximumWriteValueLength(for: .withResponse))")
        connectedDevices[peripheral.identifier.uuidString]?.didConnect()
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Log(v: "centralManager: didFailToConnect to \(peripheral.identifier)")
        connectedDevices[peripheral.identifier.uuidString]?.didDisconnect()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Log(v: "centralManager: didDisconnect from \(peripheral.identifier)")
        connectedDevices[peripheral.identifier.uuidString]?.didDisconnect()
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    }
}

// TODO: If multiple peripherals are connected, should there be a peripheral validation done?
// MARK: - CBPeripheralDelegate
extension SwiftyTeeth: CBPeripheralDelegate {
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        connectedDevices[peripheral.identifier.uuidString]?.didUpdateName()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        connectedDevices[peripheral.identifier.uuidString]?.didModifyServices(invalidatedServices: invalidatedServices)
    }
    
    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didUpdateRSSI(error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didReadRSSI(RSSI: RSSI, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didDiscoverServices(error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didDiscoverIncludedServicesFor(service: service, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didDiscoverCharacteristicsFor(service: service, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didUpdateValueFor(characteristic: characteristic, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didWriteValueFor(characteristic: characteristic, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didUpdateNotificationStateFor(characteristic: characteristic, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didDiscoverDescriptorsFor(characteristic: characteristic, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didUpdateValueFor(descriptor: descriptor, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        connectedDevices[peripheral.identifier.uuidString]?.didWriteValueFor(descriptor: descriptor, error: error)
    }
}
