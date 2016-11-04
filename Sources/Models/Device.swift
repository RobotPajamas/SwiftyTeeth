//
//  Peripheral.swift
//  SwiftyTeeth
//
//  Created by Basem Emara on 10/27/16.
//
//

import Foundation
import CoreBluetooth

open class Device {

    let peripheral: CBPeripheral
    
    init(delegate: CBPeripheralDelegate, peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral.delegate = delegate
    }
    
    deinit {
        peripheral.delegate = nil
    }
}
