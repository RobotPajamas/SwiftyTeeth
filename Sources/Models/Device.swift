//
//  Peripheral.swift
//  SwiftyTeeth
//
//  Created by Basem Emara on 10/27/16.
//
//

import Foundation
import CoreBluetooth

open class Device: NSObject {

    let peripheral: CBPeripheral
    
    var isConnected = false
    open var name: String {
        return peripheral.name ?? ""
    }
    
    open var id: String {
        return peripheral.identifier.description
    }
    
//    open var rssi: Int {
//        return peripheral.
//    }
    
    fileprivate let manager: CBCentralManager
    
    // Callbacks
    fileprivate var connectionHandler: ((Bool) -> Void)?
    fileprivate var serviceDiscoveryHandler: ((Error?) -> Void)?
    fileprivate var characteristicDiscoveryHandler: ((Error?) -> Void)?
    
    // Connection parameters
    fileprivate var autoReconnect = false
    
    init(manager: CBCentralManager, peripheral: CBPeripheral) {
        self.manager = manager
        self.peripheral = peripheral
        super.init()
        
        self.peripheral.delegate = self
    }
    
    // Annoyingly, iOS has the connection functionality sitting on the central manager, instead of on the peripheral
    // TODO: Should the completion be optional?
    open func connect(with timeout: TimeInterval? = nil, autoReconnect: Bool = true, complete: ((Bool) -> Void)?) {
        if complete != nil {
            self.connectionHandler = complete
        }
        self.autoReconnect = autoReconnect
        self.manager.connect(peripheral, options: nil)
    }
    
    open func disconnect() {
        // Disable auto reconnection when calling the disconnect API
        autoReconnect = false
        manager.cancelPeripheralConnection(peripheral)
    }
    
    open func discoverServices(with uuids: [CBUUID]? = nil, complete: @escaping (Error?) -> Void) {
        serviceDiscoveryHandler = complete
        peripheral.discoverServices(uuids)
    }

    open func discoverCharacteristics(with uuids: [CBUUID]? = nil, for service: CBService, complete: @escaping (Error?) -> Void) {
        characteristicDiscoveryHandler = complete
        peripheral.discoverCharacteristics(uuids, for: service)
    }

}


// MARK: - NSObject overrides
extension Device {
    open override var hash : Int {
        return id.hash
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? Device {
            return self.id == other.id
        } else {
            return false
        }
    }
}


// TODO: If multiple peripherals are connected, should there be a peripheral validation done?
// MARK: - Central peripheral
extension Device: CBPeripheralDelegate {
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
    }
    
    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        serviceDiscoveryHandler?(error)
        serviceDiscoveryHandler = nil
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        characteristicDiscoveryHandler?(error)
        characteristicDiscoveryHandler = nil
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

