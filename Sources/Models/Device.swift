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
        return peripheral.identifier.uuidString
    }
    
//    open var rssi: Int {
//        return peripheral.
//    }
    
    // TODO: Maybe just make this a String of Strings?
    open var discoveredServices = [CBService: [CBCharacteristic]]()
    
    fileprivate let manager: SwiftyTeeth
    
    // Callbacks
    fileprivate var connectionHandler: ((Bool) -> Void)?
    fileprivate var serviceDiscoveryHandler: (([CBService], Error?) -> Void)?        // TODO: Add CBService?
    fileprivate var characteristicDiscoveryHandler: ((Error?) -> Void)? // TODO: Add CBCharacteristic?
    
    // Connection parameters
    fileprivate var autoReconnect = false
    
    init(manager: SwiftyTeeth, peripheral: CBPeripheral) {
        self.manager = manager
        self.peripheral = peripheral
        self.peripheral.delegate = manager
    }
    
    // Annoyingly, iOS has the connection functionality sitting on the central manager, instead of on the peripheral
    // TODO: Should the completion be optional?
    open func connect(with timeout: TimeInterval? = nil, autoReconnect: Bool = true, complete: ((Bool) -> Void)?) {
        self.connectionHandler = complete
        self.autoReconnect = autoReconnect
        self.manager.connect(to: self)
        // TODO: Add timeout functionality
    }
    
    open func disconnect() {
        // Disable auto reconnection when calling the disconnect API
        autoReconnect = false
        self.manager.disconnect(from: self)
    }
    
    open func discoverServices(with uuids: [CBUUID]? = nil, complete: (([CBService], Error?) -> Void)?) {
        serviceDiscoveryHandler = complete
        print("discoverServices: \(self.peripheral) \n \(self.peripheral.delegate)")
        self.peripheral.discoverServices(uuids)        
    }

    open func discoverCharacteristics(with uuids: [CBUUID]? = nil, for service: CBService, complete: ((Error?) -> Void)?) {
        characteristicDiscoveryHandler = complete
        print("discoverCharacteristics")
        peripheral.discoverCharacteristics(uuids, for: service)
    }
}


// TODO: Instead of creating internal functions, could register connection/disconnection handlers with the Manager?
// MARK: - Connection Handlers
extension Device {
    internal func didConnect() {
        print("Calling didConnect")
        connectionHandler?(true)
    }
    
    internal func didDisconnect() {
        print("Calling didDisconnect")
        connectionHandler?(false)
        if autoReconnect == true {
            connect(complete: connectionHandler)
        }
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
// MARK: - CBPeripheralDelegate Proxy
extension Device  {
    
    internal func didUpdateName() {
        
    }
    
    internal func didModifyServices(invalidatedServices: [CBService]) {
        
    }
    
    internal func didUpdateRSSI(error: Error?) {
        
    }
    
    internal func didReadRSSI(RSSI: NSNumber, error: Error?) {
        
    }
    
    internal func didDiscoverServices(error: Error?) {
        print("didDiscoverServices")
        discoveredServices.removeAll()
        for service in peripheral.services ?? [] {
            print("Service Discovered: \(service.uuid.uuidString)")
            discoveredServices[service] = [CBCharacteristic]()
        }
        serviceDiscoveryHandler?(Array(discoveredServices.keys), error)
        serviceDiscoveryHandler = nil
    }
    
    internal func didDiscoverIncludedServicesFor(service: CBService, error: Error?) {
        
    }
    
    internal func didDiscoverCharacteristicsFor(service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor")
        discoveredServices[service]?.removeAll()
        for characteristic in service.characteristics ?? [] {
            print("Characteristic Discovered: \(characteristic.uuid.uuidString)")
            discoveredServices[service]?.append(characteristic)
        }
        characteristicDiscoveryHandler?(error)
        characteristicDiscoveryHandler = nil
    }
    
    internal func didUpdateValueFor(characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    internal func didWriteValueFor(characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    internal func didUpdateNotificationStateFor(characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    internal func didDiscoverDescriptorsFor(characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    internal func didUpdateValueFor(descriptor: CBDescriptor, error: Error?) {
        
    }
    
    internal func didWriteValueFor(descriptor: CBDescriptor, error: Error?) {
        
    }
}

