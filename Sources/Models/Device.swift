//
//  Peripheral.swift
//  SwiftyTeeth
//
//  Created by Basem Emara on 10/27/16.
//
//

import Foundation
import CoreBluetooth

open class Device : Hashable {

    let peripheral: CBPeripheral
    
    public var hashValue: Int
    
    init(delegate: CBPeripheralDelegate, peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral.delegate = delegate
        self.hashValue = peripheral.identifier.hashValue
    }
    
    deinit {
        peripheral.delegate = nil
    }
    
    public static func ==(lhs: Device, rhs: Device) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
