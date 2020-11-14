//
//  SwiftyTooth.swift
//  SwiftyTooth
//
//  Created by Suresh Joshi on 2019-11-23.
//

import CoreBluetooth
import Foundation

var swiftyToothLogger: Logger?

private struct QueueItem {
    let data: Data
    let characteristic: CBMutableCharacteristic
}

open class SwiftyTooth: NSObject {

    public static let shared = SwiftyTooth()
    
    // Only allow a single connected Central right now
    // Seems like connectivity needs to be inferred, there isn't an "isConnected" anywhere
    // This is just used to determine if we should notify out values to a subscribed central
    fileprivate var connectedCentral: String?
    fileprivate var characteristics: [CBMutableCharacteristic] = []
    fileprivate var notifyHandlers = [UUID: NotifyHandler]()
    fileprivate var readHandlers = [UUID: ReadHandler]()
    fileprivate var writeHandlers = [UUID: WriteHandler]()
    fileprivate var writeNoResponseHandlers = [UUID: WriteNoResponseHandler]()
    
    // Using a very quick thread-unsafe queue just to test this out conceptually, to see how it works
    fileprivate var notificationQueue = Deque<QueueItem>()
    
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
        advertise(name: name, uuids: uuids)
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

// MARK: - SwiftyTooth Service/Characteristics
public extension SwiftyTooth {
    func add(service: Service) {
        let cbService = CBMutableService(type: CBUUID(nsuuid: service.uuid), primary: true)
        cbService.characteristics = []
        
        for char in service.characteristics {
            var cbProperties = CBCharacteristicProperties()
            var cbAttributePermissions = CBAttributePermissions()
            
            for prop in char.properties {
                switch(prop) {
                case .read(let handler):
                    cbProperties.update(with: .read)
                    cbAttributePermissions.update(with: .readable)
                    readHandlers[char.uuid] = handler
                    
                case .notify(let handler):
                    cbProperties.update(with: .notify)
                    cbAttributePermissions.update(with: .readable)
                    notifyHandlers[char.uuid] = handler
                    
                case .write(let handler):
                    cbProperties.update(with: .write)
                    cbAttributePermissions.update(with: .writeable)
                    writeHandlers[char.uuid] = handler
                
                case .writeNoResponse(let handler):
                    cbProperties.update(with: .writeWithoutResponse)
                    cbAttributePermissions.update(with: .writeable)
                    writeNoResponseHandlers[char.uuid] = handler
                }
            }
            
            let cbChar = CBMutableCharacteristic(
                type: CBUUID(nsuuid: char.uuid),
                properties: cbProperties,
                value: nil,
                permissions: cbAttributePermissions)
            
            cbService.characteristics?.append(cbChar)
            characteristics.append(cbChar)
        }

        peripheralManager.add(cbService)
    }
}

// MARK: - SwiftyTooth Emitting Data
public extension SwiftyTooth {
    private func emitQueuedItems() {
        while notificationQueue.count != 0 {
            guard let item = notificationQueue.dequeue() else {
                return
            }

            if peripheralManager.updateValue(item.data, for: item.characteristic, onSubscribedCentrals: nil) == false {
                notificationQueue.enqueueFront(item)
                return
            }
        }
    }
    
    // Sends data to all subscribed centrals for this characteristic
    func emit(data: Data, on characteristic: Characteristic) -> Bool {
        guard let mutableCharacteristic = characteristics.first(where: { (char) -> Bool in
            char.uuid.uuidString == characteristic.uuid.uuidString
        }) else {
            Log(w: "No such characteristic found with UUID \(characteristic.uuid)")
            return false
        }
        
        notificationQueue.enqueue(QueueItem(data: data, characteristic: mutableCharacteristic))
        emitQueuedItems()
        return true
    }
}


// MARK: - Peripheral manager
extension SwiftyTooth: CBPeripheralManagerDelegate {
    
    // MARK: - Peripheral Manager State Changes
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch (peripheral.state) {
        case .unknown:
            Log(i: "Bluetooth state is unknown.")
        case .resetting:
            Log(i: "Bluetooth state is resetting.")
        case .unsupported:
            Log(i: "Bluetooth state is unsupported.")
        case .unauthorized:
            Log(i: "Bluetooth state is unauthorized.")
        case .poweredOff:
            Log(i: "Bluetooth state is powered off.")
        case .poweredOn:
            Log(i: "Bluetooth state is powered on")
        default:
            Log(i: "Bluetooth state is not in supported switches")
        }
        
        guard let state = BluetoothState(rawValue: peripheral.state.rawValue) else {
            return
        }
        stateChangedHandler?(state)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        Log(v: "Will restore state")
    }
    
    // MARK: - Peripheral Manager Services
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        Log(v: "didAdd \(service.uuid.uuidString)")
    }
    
    // MARK: - Peripheral Manager Advertisments
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        Log(v: "Started advertising with \(String(describing: error))")
    }
    
    // MARK: - Peripheral Manager Characteristic Subscriptions
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        Log(v: "didSubscribeTo \(characteristic.uuid.uuidString) \(central.maximumUpdateValueLength)")
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        Log(v: "didUnsubscribeFrom \(characteristic.uuid.uuidString)")
    }
    
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        Log(v: "peripheralManagerIsReady: Currently \(notificationQueue.count) items to transmit")
        emitQueuedItems()
    }
    
    // MARK: - Peripheral Manager Read/Write requests
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard let uuid = UUID(cbuuid: request.characteristic.uuid) else {
            Log(w: "didReceiveRead: CBATTRequest contained invalid UUID (\(request.characteristic.uuid))")
            peripheralManager.respond(to: request, withResult: .unlikelyError)
            return
        }
        
        guard let handler = readHandlers[uuid] else {
            Log(w: "didReceiveRead: No associated read handler with UUID \(uuid)")
            peripheralManager.respond(to: request, withResult: .unlikelyError)
            return
        }
        
        handler { (result) in
            if let value = try? result.get() {
                request.value = value
                peripheralManager.respond(to: request, withResult: .success)
            } else {
                // TODO: Until there is a better idea, should errors be returned? Or an empty success?
                peripheralManager.respond(to: request, withResult: .unlikelyError)
            }
        }
    }
    
    // TODO: Only works for 1 request right now
    // TODO: Do we need a "respond" if this is an unacknowledged write? What if it's both ack and unack'd?
    // Note: If you have acknowledged and unacknowledged writes on the same characteristic, they will BOTH be called (need to review the BLE spec to see how this should be handled)
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard requests.isEmpty != true else {
            Log(e: "didReceiveWrite: There are no requests somehow")
            return
        }
        
        if requests.count > 1 {
            Log(i: "didReceiveWrite: TODO: Received multiple requests - but only handling first one...")
        }
        
        // TODO: Handle multiple requests
        let firstRequest = requests[0]
        
        guard let uuid = UUID(cbuuid: firstRequest.characteristic.uuid) else {
            Log(w: "didReceiveWrite: CBATTRequest contained invalid UUID (\(firstRequest.characteristic.uuid))")
            peripheralManager.respond(to: firstRequest, withResult: .unlikelyError)
            return
        }
        
        let noResponseHandler = writeNoResponseHandlers[uuid]
        noResponseHandler?(firstRequest.value)

        let handler = writeHandlers[uuid]
        handler?(firstRequest.value) { (result) in
            if ((try? result.get()) != nil) {
                peripheralManager.respond(to: firstRequest, withResult: .success)
            } else {
                // TODO: Until there is a better idea, should errors be returned? Or an empty success?
                // TODO: If one of these handlers fails, I think we're supposed to fail them all
                peripheralManager.respond(to: firstRequest, withResult: .unlikelyError)
            }
        }
    }
}
