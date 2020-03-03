//
//  SwiftyTooth.swift
//  SwiftyTeeth
//
//  Created by Suresh Joshi on 2019-11-23.
//

import Foundation
import CoreBluetooth

var swiftyToothLogger: Logger?

public typealias ReadHandler = ((Result<Data, Error>) -> Void)
public typealias WriteHandler = ((Result<Data?, Error>) -> Void)
public typealias NotifyHandler = ((Result<Data, Error>) -> Void)

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
                    writeHandlers[char.uuid] = handler
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
    // Sends data to all subscribed centrals for this characteristic
    func emit(data: Data, on characteristic: Characteristic) {
        guard let mutableCharacteristic = characteristics.first(where: { (char) -> Bool in
            char.uuid.uuidString == characteristic.uuid.uuidString
        }) else {
            return
        }
        
        peripheralManager.updateValue(data, for: mutableCharacteristic, onSubscribedCentrals: nil)
    }
}


// MARK: - Peripheral manager
extension SwiftyTooth: CBPeripheralManagerDelegate {
    
    // MARK: - Peripheral Manager State Changes
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch (peripheral.state) {
        case .unknown:
            print("Bluetooth state is unknown.")
        case .resetting:
            print("Bluetooth state is resetting.")
        case .unsupported:
            print("Bluetooth state is unsupported.")
        case .unauthorized:
            print("Bluetooth state is unauthorized.")
        case .poweredOff:
            print("Bluetooth state is powered off.")
        case .poweredOn:
            print("Bluetooth state is powered on")
        default:
            print("Bluetooth state is not in supported switches")
        }
        
        guard let state = BluetoothState(rawValue: peripheral.state.rawValue) else {
            return
        }
        stateChangedHandler?(state)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print("Will restore state")
    }
    
    // MARK: - Peripheral Manager Services
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("didAdd \(service.uuid.uuidString)")
    }
    
    // MARK: - Peripheral Manager Advertisments
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
//        Log(v: "Started advertising")
        print("Started advertising with \(error)")
    }
    
    // MARK: - Peripheral Manager Characteristic Subscriptions
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("didSubscribeTo \(characteristic.uuid.uuidString) \(central.maximumUpdateValueLength)")
        
        
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("didUnsubscribeFrom \(characteristic.uuid.uuidString)")
    }
    
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("peripheralManagerIsReady")
    }
    
    // MARK: - Peripheral Manager Read/Write requests
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("didReceiveRead")
        
        
        
        request.value = Data(base64Encoded: "Hello")
        peripheralManager.respond(to: request, withResult: .success)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("didReceiveWrite")
        for request in requests {
            let uuid = UUID(uuidString: request.characteristic.uuid.uuidString)!
            writeHandlers[uuid]?(.success(request.value))
        }
//        peripheralManager.respond(to: <#T##CBATTRequest#>, withResult: <#T##CBATTError.Code#>)
    }
    
}
