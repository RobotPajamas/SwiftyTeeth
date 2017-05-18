//
//  Peripheral.swift
//  SwiftyTeeth
//
//  Created by Basem Emara on 10/27/16.
//
//

import Foundation
import CoreBluetooth

// Note: The design of this class will (eventually, and if reasonable) attempt to keep APIs unaware of CoreBluetooth
// while at the same time making use of them internally as a convenience
// NotificationHandler is an example of this, as it could be a dictionary using a String key - but that just adds extra indirection internally,
// where all CBCharacterisics need to be dereferenced by uuid then uuidString. Internally, this adds no value - and adds risk.
open class Device: NSObject {
    public typealias ConnectionHandler = ((Bool) -> Void)
    public typealias ServiceDiscovery = (([CBService], Error?) -> Void)
    public typealias CharacteristicDiscovery = ((CBService, [CBCharacteristic], Error?) -> Void)
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
    
    //    open var connectionState: StateEnumOfSomeSort {
    //        return peripheral.state
    //    }
    
    
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
    
    fileprivate var notificationHandler = [CBCharacteristic: ReadHandler]()
    
    // Connection parameters
    fileprivate var autoReconnect = false
    
    init(manager: SwiftyTeeth, peripheral: CBPeripheral) {
        self.manager = manager
        self.peripheral = peripheral
        self.peripheral.delegate = manager
    }
    
    convenience init(copy: Device) {
        self.init(manager: copy.manager, peripheral: copy.peripheral)
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
    
    open func disconnect(autoReconnect: Bool = false) {
        // Disable auto reconnection when calling the disconnect API
        self.autoReconnect = autoReconnect
        self.manager.disconnect(from: self)
    }
}


// MARK: - GATT operations
extension Device {
    // TODO: Make CBUUID into strings
    open func discoverServices(with uuids: [CBUUID]? = nil, complete: ServiceDiscovery?) {
        guard isConnected == true else {
            print("Device: Not connected - cannot discoverServices")
            return
        }
        
        serviceDiscoveryHandler = complete
        print("Device: discoverServices: \(self.peripheral) \n \(self.peripheral.delegate)")
        self.peripheral.discoverServices(uuids)
    }
    
    // TODO: Make CBUUID into strings
    // TODO: Make service a UUID?
    open func discoverCharacteristics(with uuids: [CBUUID]? = nil, for service: CBService, complete: CharacteristicDiscovery?) {
        guard isConnected == true else {
            print("Device: Not connected - cannot discoverCharacteristics")
            return
        }
        
        characteristicDiscoveryHandler = complete
        print("Device: discoverCharacteristics")
        peripheral.discoverCharacteristics(uuids, for: service)
    }
    
    open func read(from characteristic: String, in service: String, complete: ReadHandler?) {
        guard let targetService = peripheral.services?.find(uuidString: service),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic) else {
                return
        }
        
        guard isConnected == true else {
            print("Device: Not connected - cannot read")
            return
        }
        
        readHandler = complete
        peripheral.readValue(for: targetCharacteristic)
    }
    
    open func write(data: Data, to characteristic: String, in service: String, complete: WriteHandler? = nil) {
        guard let targetService = peripheral.services?.find(uuidString: service),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic) else {
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
    
    // TODO: Adding some pre-conditions libraries/toolkits could streamline the initial clutter
    open func subscribe(to characteristic: String, in service: String, complete: ReadHandler?) {
        guard let targetService = peripheral.services?.find(uuidString: service),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic) else {
                return
        }
        
        guard isConnected == true else {
            print("Device: Not connected - cannot write")
            return
        }
        
        guard targetCharacteristic.isNotifying == false else {
            return
        }
        
        // TODO: Can using just the characteristic UUID cause a conflict if there is an identical characteristic in another service? Can't recall if legal
        notificationHandler[targetCharacteristic] = complete
        peripheral.setNotifyValue(true, for: targetCharacteristic)
    }
    
    // TODO: Faster probably to just iterate through the notification handler instead of current method
    open func unsubscribe(from characteristic: String, in service: String) {
        guard let targetService = peripheral.services?.find(uuidString: service),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic) else {
                return
        }

        guard isConnected == true else {
            print("Device: Not connected - cannot write")
            return
        }
        
        guard targetCharacteristic.isNotifying == true else {
            return
        }
        
        notificationHandler.removeValue(forKey: targetCharacteristic)
        peripheral.setNotifyValue(false, for: targetCharacteristic)
    }
    
    open func unsubscribeAll() {
        // TODO
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
        characteristicDiscoveryHandler?(service, characteristics, error)
    }
    
    func didUpdateValueFor(characteristic: CBCharacteristic, error: Error?) {
        print("Device: didUpdateValueFor: \(characteristic.uuid.uuidString) with: \(characteristic.value)")
        readHandler?(characteristic.value, error)
        readHandler = nil
        notificationHandler[characteristic]?(characteristic.value, error)
    }
    
    func didWriteValueFor(characteristic: CBCharacteristic, error: Error?) {
        print("Device: didWriteValueFor: \(characteristic.uuid.uuidString)")
        writeHandler?(error)
        writeHandler = nil
    }
    
    // This is equivalent to a direct READ from the characteristic
    func didUpdateNotificationStateFor(characteristic: CBCharacteristic, error: Error?) {
        print("Device: didUpdateNotificationStateFor: \(characteristic.uuid.uuidString)")
        notificationHandler[characteristic]?(characteristic.value, error)
    }
    
    func didDiscoverDescriptorsFor(characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func didUpdateValueFor(descriptor: CBDescriptor, error: Error?) {
        
    }
    
    func didWriteValueFor(descriptor: CBDescriptor, error: Error?) {
        
    }
}

