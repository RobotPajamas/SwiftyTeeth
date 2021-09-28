//
//  CBCharacterisic.swift
//  SwiftyTeeth
//
//  Created by Suresh Joshi on 2017-02-05.
//
//

import CoreBluetooth

internal extension CBCharacteristic {
    var compositeId: String {
        // TODO: What is the correct way to handle this change?
        // https://developer.apple.com/documentation/corebluetooth/cbcharacteristic/1518728-service?changes=latest_minor
        return service?.uuid.uuidString ?? "" + uuid.uuidString
    }
    
    func equals(_ uuidString: String) -> Bool {
        return self.uuid.uuidString.lowercased() == uuidString.lowercased()
    }
}

internal extension Array where Element: CBCharacteristic {
    func find(uuidString: String) -> CBCharacteristic? {
        return self.first(where: {$0.equals(uuidString)})
    }
}
