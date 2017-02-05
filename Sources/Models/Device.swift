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
    public typealias ConnectionHandler = ((Bool) -> Void)
    public typealias ServiceDiscovery = (([CBService], Error?) -> Void)
    public typealias CharacteristicDiscovery = (([CBCharacteristic], Error?) -> Void)
    public typealias ReadHandler = ((Data?, Error?) -> Void)
    public typealias WriteHandler = ((Error?) -> Void)
    
    let peripheral: CBPeripheral
    
    open var isConnected: Bool {
        return peripheral.state == .connected
    }
    
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

    fileprivate var connectionHandler: ConnectionHandler?
    // Should these handlers be queues?
    fileprivate var serviceDiscoveryHandler: ServiceDiscovery?
    fileprivate var characteristicDiscoveryHandler: CharacteristicDiscovery?
    fileprivate var readHandler: ReadHandler?
    fileprivate var writeHandler: WriteHandler?
    
    // Connection parameters
    fileprivate var autoReconnect = false
    
    init(manager: SwiftyTeeth, peripheral: CBPeripheral) {
        self.manager = manager
        self.peripheral = peripheral
        self.peripheral.delegate = manager
    }
}

// MARK: - Connection operations
extension Device {
    // Annoyingly, iOS has the connection functionality sitting on the central manager, instead of on the peripheral
    // TODO: Should the completion be optional?
    open func connect(with timeout: TimeInterval? = nil, autoReconnect: Bool = true, complete: ConnectionHandler?) {
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
}


// MARK: - GATT operations
extension Device {
    open func discoverServices(with uuids: [CBUUID]? = nil, complete: ServiceDiscovery?) {
        guard isConnected == true else {
            print("Device: Not connected - cannot discoverServices")
            return
        }
        
        serviceDiscoveryHandler = complete
        print("Device: discoverServices: \(self.peripheral) \n \(self.peripheral.delegate)")
        self.peripheral.discoverServices(uuids)
    }
    
    open func discoverCharacteristics(with uuids: [CBUUID]? = nil, for service: CBService, complete: CharacteristicDiscovery?) {
        guard isConnected == true else {
            print("Device: Not connected - cannot discoverCharacteristics")
            return
        }
        
        characteristicDiscoveryHandler = complete
        print("Device: discoverCharacteristics")
        peripheral.discoverCharacteristics(uuids, for: service)
    }
    
    // TODO: Create convenience extensions for CBUUID and CBService and CBCharacteristic
    open func read(from characteristic: String, in service: String, complete: ReadHandler?) {
        // Iterate through Services/Characteristics to find desired
        // TODO: Hashmaps are faster -
        guard let targetService = peripheral.services?.first(where: {$0.uuid.uuidString.lowercased() == service.lowercased()}),
            let targetCharacteristic = targetService.characteristics?.first(where: {$0.uuid.uuidString.lowercased() == characteristic.lowercased()}) else {
                return
        }
        
        guard isConnected == true else {
            print("Device: Not connected - cannot read")
            return
        }
        
        readHandler = complete
        peripheral.readValue(for: targetCharacteristic)
    }
    
    // TODO: Create convenience extensions for CBUUID and CBService and CBCharacteristic
    open func write(data: Data, to characteristic: String, in service: String, complete: WriteHandler?) {
        // Iterate through Services/Characteristics to find desired target
        guard let targetService = peripheral.services?.first(where: {$0.uuid.uuidString.lowercased() == service.lowercased()}),
            let targetCharacteristic = targetService.characteristics?.first(where: {$0.uuid.uuidString.lowercased() == characteristic.lowercased()}) else {
                return
        }
        
        guard isConnected == true else {
            print("Device: Not connected - cannot write")
            return
        }
        
        writeHandler = complete
        var writeType = CBCharacteristicWriteType.withResponse
        if complete == nil {
            writeType = .withoutResponse
        }
        peripheral.writeValue(data, for: targetCharacteristic, type: writeType)
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


// TODO: Instead of creating internal functions, could register connection/disconnection handlers with the Manager?
// MARK: - Connection Handler Proxy
internal extension Device {
    
    func didConnect() {
        connectionHandler?(true)
    }
    
    func didDisconnect() {
        connectionHandler?(false)
        if autoReconnect == true {
            connect(complete: connectionHandler)
        }
    }
}


// TODO: If multiple peripherals are connected, should there be a peripheral validation done?
// MARK: - CBPeripheralDelegate Proxy
internal extension Device  {
    
    func didUpdateName() {
        
    }
    
    func didModifyServices(invalidatedServices: [CBService]) {
        
    }
    
    func didUpdateRSSI(error: Error?) {
        
    }
    
    func didReadRSSI(RSSI: NSNumber, error: Error?) {
        
    }
    
    func didDiscoverServices(error: Error?) {
        discoveredServices.removeAll()
        peripheral.services?.forEach({ service in
            print("Device: Service Discovered: \(service.uuid.uuidString)")
            discoveredServices[service] = [CBCharacteristic]()
        })
        serviceDiscoveryHandler?(Array(discoveredServices.keys), error)
//        serviceDiscoveryHandler = nil
    }
    
    func didDiscoverIncludedServicesFor(service: CBService, error: Error?) {
        
    }
    
    func didDiscoverCharacteristicsFor(service: CBService, error: Error?) {
        discoveredServices[service]?.removeAll()
        var characteristics = [CBCharacteristic]()
        service.characteristics?.forEach({ characteristic in
            print("Device: Characteristic Discovered: \(characteristic.uuid.uuidString)")
            characteristics.append(characteristic)
        })
        discoveredServices[service]? = characteristics
        characteristicDiscoveryHandler?(characteristics, error)
//        characteristicDiscoveryHandler = nil
    }
    
    func didUpdateValueFor(characteristic: CBCharacteristic, error: Error?) {
        print("Device: didUpdateValueFor: \(characteristic.uuid.uuidString) with: \(characteristic.value)")
        readHandler?(characteristic.value, error)
        readHandler = nil
    }
    
    func didWriteValueFor(characteristic: CBCharacteristic, error: Error?) {
        print("Device: didWriteValueFor: \(characteristic.uuid.uuidString)")
    }
    
    func didUpdateNotificationStateFor(characteristic: CBCharacteristic, error: Error?) {
        print("Device: didUpdateNotificationStateFor: \(characteristic.uuid.uuidString)")
    }
    
    func didDiscoverDescriptorsFor(characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func didUpdateValueFor(descriptor: CBDescriptor, error: Error?) {
        
    }
    
    func didWriteValueFor(descriptor: CBDescriptor, error: Error?) {
        
    }
}

