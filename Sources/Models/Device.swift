//
//  Peripheral.swift
//  SwiftyTeeth
//
//  Created by Basem Emara on 10/27/16.
//
//

import Foundation
import CoreBluetooth

public typealias DiscoveredCharacteristic = (service: CBService, characteristics: [CBCharacteristic])
public typealias ConnectionHandler = ((Bool) -> Void)
public typealias ServiceDiscovery = ((Result<[CBService]>) -> Void)
public typealias CharacteristicDiscovery = ((Result<DiscoveredCharacteristic>) -> Void)
public typealias ReadHandler = ((Result<Data>) -> Void)
public typealias WriteHandler = ((Result<Void>) -> Void)

// Note: The design of this class will (eventually, and if reasonable) attempt to keep APIs unaware of CoreBluetooth
// while at the same time making use of them internally as a convenience
// NotificationHandler is an example of this, as it could be a dictionary using a String key - but that just adds extra indirection internally,
// where all CBCharacterisics need to be dereferenced by uuid then uuidString. Internally, this adds no value - and adds risk.
open class Device: NSObject {
    fileprivate let tag = "SwiftyDevice"
    
    let peripheral: CBPeripheral
    
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
 
    lazy var queue: SwiftyQueue = {
        let instance = OperationQueue()
        instance.maxConcurrentOperationCount = 1 // Ensure serial queue
        return instance
    }()
    
    public init(manager: SwiftyTeeth, peripheral: CBPeripheral) {
        self.manager = manager
        self.peripheral = peripheral
        self.peripheral.delegate = manager
    }
    
    public convenience init(copy: Device) {
        self.init(manager: copy.manager, peripheral: copy.peripheral)
    }
}

// MARK: Computed properties
extension Device {
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
}

// MARK: - Connection operations
extension Device {
    // Annoyingly, iOS has the connection functionality sitting on the central manager, instead of on the peripheral
    // TODO: Should the completion be optional?
    open func connect(with timeout: TimeInterval? = nil, autoReconnect: Bool = true, complete: ConnectionHandler?) {
        Log(v: "Calling connect", tag: tag)
        self.connectionHandler = complete
        self.autoReconnect = autoReconnect
        self.manager.connect(to: self)
        // TODO: Add timeout functionality
    }
    
    open func disconnect(autoReconnect: Bool = false) {
        // Disable auto reconnection when calling the disconnect API
        Log(v: "Calling disconnect", tag: tag)
        self.autoReconnect = autoReconnect
        self.manager.disconnect(from: self)
    }
}


// MARK: - GATT operations
extension Device {
    // TODO: Make CBUUID into strings
    open func discoverServices(with uuids: [CBUUID]? = nil, complete: ServiceDiscovery?) {
        guard isConnected == true else {
            Log(v: "Not connected - cannot discoverServices", tag: tag)
            return
        }
        
        serviceDiscoveryHandler = complete
        Log(v: "discoverServices: \(self.peripheral) \n \(String(describing: self.peripheral.delegate))", tag: tag)
        self.peripheral.discoverServices(uuids)
    }
    
    // TODO: Make CBUUID into strings
    // TODO: Make service a UUID?
    open func discoverCharacteristics(with uuids: [CBUUID]? = nil, for service: CBService, complete: CharacteristicDiscovery?) {
        guard isConnected == true else {
            Log(v: "Not connected - cannot discoverCharacteristics", tag: tag)
            return
        }
        
        characteristicDiscoveryHandler = complete
        Log(v: "discoverCharacteristics", tag: tag)
        peripheral.discoverCharacteristics(uuids, for: service)
    }
    
    open func read(from characteristic: String, in service: String, complete: ReadHandler?) {
        guard let targetService = peripheral.services?.find(uuidString: service),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic) else {
                return
        }
        
        let item = QueueItem<Data>(
            name: targetCharacteristic.compositeId,
            execution: {
                guard self.isConnected == true else {
                    Log(v: "Not connected - cannot read", tag: self.tag)
                    return
                }
                // readHandler = complete
                self.peripheral.readValue(for: targetCharacteristic)
            }, callback: complete)
        queue.pushBack(item)
    }
    
    open func write(data: Data, to characteristic: String, in service: String, complete: WriteHandler? = nil) {
        guard let targetService = peripheral.services?.find(uuidString: service),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic) else {
                return
        }
        
        guard isConnected == true else {
            Log(v: "Not connected - cannot write", tag: tag)
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
            Log(v: "Not connected - cannot write", tag: tag)
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
            Log(v: "Not connected - cannot write", tag: tag)
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
        Log(v: "didConnect: Calling connection handler: Is handler nil? \(connectionHandler == nil)", tag: tag)
        connectionHandler?(true)
    }
    
    func didDisconnect() {
        Log(v: "didDisconnect: Calling disconnection handler: Is handler nil? \(connectionHandler == nil)", tag: tag)
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
            Log(v: "Service Discovered: \(service.uuid.uuidString)", tag: tag)
            discoveredServices[service] = [CBCharacteristic]()
        })
        
        var result: Result<[CBService]> = .success(Array(discoveredServices.keys))
        if let e = error {
            result = .failure(e)
        }
        
        serviceDiscoveryHandler?(result)
    }
    
    func didDiscoverIncludedServicesFor(service: CBService, error: Error?) {
    }
    
    func didDiscoverCharacteristicsFor(service: CBService, error: Error?) {
        discoveredServices[service]?.removeAll()
        
        var characteristics = [CBCharacteristic]()
        service.characteristics?.forEach({ characteristic in
            Log(v: "Characteristic Discovered: \(characteristic.uuid.uuidString)", tag: tag)
            characteristics.append(characteristic)
        })
        
        discoveredServices[service]? = characteristics
        var result: Result<DiscoveredCharacteristic> = .success((service: service, characteristics: characteristics))
        if let e = error {
            result = .failure(e)
        }
        characteristicDiscoveryHandler?(result)
    }
    
    func didUpdateValueFor(characteristic: CBCharacteristic, error: Error?) {
        Log(v: "didUpdateValueFor: \(characteristic.uuid.uuidString) with: \(String(describing: characteristic.value))", tag: tag)
        
        var result: Result<Data> = .success(characteristic.value ?? Data())
        if let e = error {
            result = .failure(e)
        }
        
        readHandler?(result)
        readHandler = nil
        notificationHandler[characteristic]?(result)
    }
    
    func didWriteValueFor(characteristic: CBCharacteristic, error: Error?) {
        Log(v: "didWriteValueFor: \(characteristic.uuid.uuidString)", tag: tag)
    
        var result: Result<Void> = .success(())
        if let e = error {
            result = .failure(e)
        }
    
        writeHandler?(result)
        writeHandler = nil
    }
    
    // This is equivalent to a direct READ from the characteristic
    func didUpdateNotificationStateFor(characteristic: CBCharacteristic, error: Error?) {
        Log(v: "didUpdateNotificationStateFor: \(characteristic.uuid.uuidString)", tag: tag)
        var result: Result<Data> = .success(characteristic.value ?? Data())
        if let e = error {
            result = .failure(e)
        }
        notificationHandler[characteristic]?(result)
    }
    
    func didDiscoverDescriptorsFor(characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func didUpdateValueFor(descriptor: CBDescriptor, error: Error?) {
        
    }
    
    func didWriteValueFor(descriptor: CBDescriptor, error: Error?) {
        
    }
}

