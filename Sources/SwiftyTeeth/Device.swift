//
//  Peripheral.swift
//  SwiftyTeeth
//
//  Created by Basem Emara on 10/27/16.
//
//

import Foundation
import CoreBluetooth

public typealias DiscoveredCharacteristic = (service: Service, characteristics: [Characteristic])
public typealias ServiceDiscovery = ((Result<[Service], Error>) -> Void)
public typealias CharacteristicDiscovery = ((Result<DiscoveredCharacteristic, Error>) -> Void)

public enum ConnectionError: Error {
    case disconnected
}


// Note: The design of this class will (eventually, and if reasonable) attempt to keep APIs unaware of CoreBluetooth
// while at the same time making use of them internally as a convenience
// NotificationHandler is an example of this, as it could be a dictionary using a String key - but that just adds extra indirection internally,
// where all CBCharacterisics need to be dereferenced by uuid then uuidString. Internally, this adds no value - and adds risk.
open class Device: NSObject {
    fileprivate let tag = "SwiftyDevice"
    
    let peripheral: CBPeripheral
    var discoveredServices = [UUID: Service]()
    
    private let manager: SwiftyTeeth

    public var connectionStateChangedHandler: ((ConnectionState) -> Void)? {
        didSet {
            // TODO: Replace this with an observing property on peripheral.state
            connectionStateChangedHandler?(connectionState)
        }
    }

    private var connectionHandler: ((ConnectionState) -> Void)?
    private var notificationHandler = [CBCharacteristic: ((Result<Data, Error>) -> Void)]()
    
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
    open var connectionState: ConnectionState {
        switch peripheral.state {
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .disconnecting:
            return .disconnecting
        case .disconnected:
            return .disconnected
        @unknown default:
            return .disconnected
        }
    }

    open var isConnected: Bool {
        return connectionState == .connected
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
}

// MARK: - Connection operations
extension Device {
    // Annoyingly, iOS has the connection functionality sitting on the central manager, instead of on the peripheral
    // TODO: Should the completion be optional?
    open func connect(with timeout: TimeInterval? = nil, autoReconnect: Bool = true, complete: ((ConnectionState) -> Void)?) {
        Log(v: "Calling connect", tag: tag)
        connectionStateChangedHandler?(.connecting)
        self.connectionHandler = complete
        self.autoReconnect = autoReconnect
        self.manager.connect(to: self)
        // TODO: Add timeout functionality
    }
    
    open func disconnect(autoReconnect: Bool = false) {
        // Disable auto reconnection when calling the disconnect API
        Log(v: "Calling disconnect", tag: tag)
        connectionStateChangedHandler?(.disconnecting)
        self.autoReconnect = autoReconnect
        self.manager.disconnect(from: self)
    }
}


// MARK: - GATT operations
extension Device {
    
    // TODO: Make CBUUID into strings
    open func discoverServices(with uuids: [UUID]? = nil, complete: ServiceDiscovery?) {
        let item = QueueItem<[Service]>(
            name: "discoverServices", // TODO: Need better than a hardcoded string
            execution: { (cb) in

                guard self.isConnected == true else {
                    Log(v: "Not connected - cannot discoverServices", tag: self.tag)
                    cb(.failure(ConnectionError.disconnected))
                    return
                }
                Log(v: "discoverServices: \(self.peripheral) \n \(String(describing: self.peripheral.delegate))", tag: self.tag)
                let cbuuids = uuids == nil ? nil : uuids!.map { CBUUID(nsuuid: $0) }
                self.peripheral.discoverServices(cbuuids)
        },
            callback: { (result, done) in
                complete?(result)
                done()
        })
        
        queue.pushBack(item)
    }

    open func discoverCharacteristics(with uuids: [UUID]? = nil, for service: Service, complete: CharacteristicDiscovery?) {
        let item = QueueItem<DiscoveredCharacteristic>(
            name: service.uuid.uuidString,
            execution: { (cb) in
                guard self.isConnected == true else {
                    Log(v: "Not connected - cannot discoverCharacteristics", tag: self.tag)
                    cb(.failure(ConnectionError.disconnected))
                    return
                }

                guard let cbService = self.peripheral.services?.find(uuidString: service.uuid.uuidString) else {
                    Log(w: "Service not found on peripheral - cannot discoverCharacteristics", tag: self.tag)
                    cb(.failure(ConnectionError.disconnected)) // TODO: Replace this error
                    return
                }

                Log(v: "discoverCharacteristics", tag: self.tag)
                let cbuuids = uuids == nil ? nil : uuids!.map { CBUUID(nsuuid: $0) }
                self.peripheral.discoverCharacteristics(cbuuids, for: cbService)
        },
            callback: { (result, done) in
                complete?(result)
                done()
        })
        
        queue.pushBack(item)
    }
    
    open func read(from characteristic: UUID, in service: UUID, complete: ((Result<Data, Error>) -> Void)?) {
        guard let targetService = peripheral.services?.find(uuidString: service.uuidString),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic.uuidString) else {
                return
        }
        
        let item = QueueItem<Data>(
            name: targetCharacteristic.compositeId,
            execution: { (cb) in
                guard self.isConnected == true else {
                    Log(v: "Not connected - cannot read", tag: self.tag)
                    cb(.failure(ConnectionError.disconnected))
                    return
                }
                self.peripheral.readValue(for: targetCharacteristic)
            },
            callback: { (result, done) in
                complete?(result)
                done()
        })
    
        queue.pushBack(item)
    }
    
    open func write(data: Data, to characteristic: UUID, in service: UUID, type: CBCharacteristicWriteType = .withResponse, complete: ((Result<Void, Error>) -> Void)? = nil) {
        guard let targetService = peripheral.services?.find(uuidString: service.uuidString),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic.uuidString) else {
                return
        }
        
        let item = QueueItem<Void>(
            name: targetCharacteristic.compositeId,
            execution: { (cb) in
                guard self.isConnected == true else {
                    Log(v: "Not connected - cannot write", tag: self.tag)
                    cb(.failure(ConnectionError.disconnected))
                    return
                }
                self.peripheral.writeValue(data, for: targetCharacteristic, type: type)
        }, callback: { (result, done) in
            complete?(result)
            done()
        })
        queue.pushBack(item)
    }
    
    // TODO: Adding some pre-conditions libraries/toolkits could streamline the initial clutter
    open func subscribe(to characteristic: UUID, in service: UUID, complete: ((Result<Data, Error>) -> Void)?) {
        guard let targetService = peripheral.services?.find(uuidString: service.uuidString),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic.uuidString) else {
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
        // TODO: Maybe use new compositeId? Merges service and characteristic IDs
        notificationHandler[targetCharacteristic] = complete
        peripheral.setNotifyValue(true, for: targetCharacteristic)
    }
    
    // TODO: Faster probably to just iterate through the notification handler instead of current method
    open func unsubscribe(from characteristic: UUID, in service: UUID) {
        guard let targetService = peripheral.services?.find(uuidString: service.uuidString),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic.uuidString) else {
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
        connectionHandler?(.connected)
        connectionStateChangedHandler?(.connected)
    }
    
    func didDisconnect() {
        Log(v: "didDisconnect: Calling disconnection handler: Is handler nil? \(connectionHandler == nil)", tag: tag)
        queue.cancelAll()

        connectionHandler?(.disconnected)
        connectionStateChangedHandler?(.disconnected)
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
//        discoveredServices.removeAll()

        let services = peripheral.services?.compactMap { (cbService) -> Service? in
            Log(v: "Service Discovered: \(cbService.uuid.uuidString)", tag: tag)
            guard let uuid = UUID(cbuuid: cbService.uuid) else {
                return nil
            }
            return Service(uuid: uuid, characteristics: [])
        } ?? []

        discoveredServices = Dictionary(uniqueKeysWithValues: zip(services.map {$0.uuid}, services))

        var result: Result<[Service], Error> = .success(Array(discoveredServices.values))
        if let error = error {
            result = .failure(error)
        }
        
        let item = queue.items.first { (operation) -> Bool in
            operation.isExecuting && operation.name == "discoverServices"
            } as? QueueItem<[Service]>
        item?.notify(result)
    }
    
    func didDiscoverIncludedServicesFor(service: CBService, error: Error?) {
    }
    
    func didDiscoverCharacteristicsFor(service: CBService, error: Error?) {
        guard let uuid = UUID(cbuuid: service.uuid) else {
            // TODO: What to do? Maybe a defer?
            return
        }

        let characteristics = service.characteristics?.compactMap { cbCharacteristic -> Characteristic? in
            Log(v: "Characteristic Discovered: \(cbCharacteristic.uuid.uuidString)", tag: tag)
            guard let uuid = UUID(cbuuid: cbCharacteristic.uuid) else {
               return nil
           }
            return Characteristic(uuid: uuid, properties: [])
        } ?? []

        let service = Service(uuid: uuid, characteristics: characteristics)
        discoveredServices[uuid] = service

        var result: Result<DiscoveredCharacteristic, Error> = .success((service: service, characteristics: characteristics))
        if let error = error {
            result = .failure(error)
        }
        
        let item = queue.items.first { (operation) -> Bool in
            operation.isExecuting && operation.name == service.uuid.uuidString
            } as? QueueItem<DiscoveredCharacteristic>
        item?.notify(result)
    }
    
    func didUpdateValueFor(characteristic: CBCharacteristic, error: Error?) {
        Log(v: "didUpdateValueFor: \(characteristic.uuid.uuidString) with: \(String(describing: characteristic.value))", tag: tag)
        
        var result: Result<Data, Error> = .success(characteristic.value ?? Data())
        if let e = error {
            result = .failure(e)
        }
        
        let item = queue.items.first { (operation) -> Bool in
            operation.isExecuting && operation.name == characteristic.compositeId
            } as? QueueItem<Data>
        item?.notify(result)
        notificationHandler[characteristic]?(result)
    }
    
    func didWriteValueFor(characteristic: CBCharacteristic, error: Error?) {
        Log(v: "didWriteValueFor: \(characteristic.uuid.uuidString)", tag: tag)
    
        var result: Result<Void, Error> = .success(())
        if let e = error {
            result = .failure(e)
        }
        
        let item = queue.items.first { (operation) -> Bool in
            operation.isExecuting && operation.name == characteristic.compositeId
        } as? QueueItem<Void>
        item?.notify(result)
    }
    
    // This is equivalent to a direct READ from the characteristic
    func didUpdateNotificationStateFor(characteristic: CBCharacteristic, error: Error?) {
        Log(v: "didUpdateNotificationStateFor: \(characteristic.uuid.uuidString)", tag: tag)
        var result: Result<Data, Error> = .success(characteristic.value ?? Data())
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

