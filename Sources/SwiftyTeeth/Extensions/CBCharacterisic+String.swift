//
//  CBCharacterisic.swift
//  SwiftyTeeth
//
//  Created by Suresh Joshi on 2017-02-05.
//
//

import CoreBluetooth

extension CBCharacteristic {
    var compositeId: String {
        // TODO: What is the correct way to handle this change? Need to support iOS15 (optional) and pre-iOS15 (non-optional)
        // https://developer.apple.com/documentation/corebluetooth/cbcharacteristic/1518728-service?changes=latest_minor
        let maybeService: CBService? = service
        // TODO: Why would the service no longer exist? Already destroyed?
        return maybeService?.uuid.uuidString ?? "" + uuid.uuidString
    }

    func equals(_ uuidString: String) -> Bool {
        return self.uuid.uuidString.lowercased() == uuidString.lowercased()
    }
}

extension Array where Element: CBCharacteristic {
    func find(uuidString: String) -> CBCharacteristic? {
        return self.first(where: { $0.equals(uuidString) })
    }
}
