//
//  Characteristic.swift
//  SwiftyTeeth
//
//  Created by SJ on 2020-03-02.
//

import CoreBluetooth
import Foundation

public typealias ReadHandler = ((Result<Data?, Error>) -> Void) -> Void
public typealias WriteHandler = (Data?, (Result<Void, Error>) -> Void) -> Void
public typealias WriteNoResponseHandler = (Data?) -> Void
public typealias NotifyHandler = (Result<Data, Error>) -> Void

// Maybe put callback in this enum?
public enum Property {
    case read(onRead: ReadHandler)
    case notify(onNotify: NotifyHandler)
    case write(onWrite: WriteHandler)
    case writeNoResponse(onWrite: WriteNoResponseHandler)
    
    var isReadable: Bool {
        switch self {
        case .read, .notify:
            return true
        case .write, .writeNoResponse:
            return false
        }
    }
    
    var isWriteable: Bool {
        return !isReadable
    }
}

public struct Characteristic {
    public let uuid: UUID
    public let properties: [Property]
    
    
    public init(uuid: UUID, properties: [Property]) {
        self.uuid = uuid
        self.properties = properties
    }
}
