//
//  BluetoothState.swift
//  SwiftyTooth
//
//  Created by Suresh Joshi on 2019-11-23.
//

// Maps to CBManagerState and CBCentralManagerState
public enum BluetoothState: Int {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}
