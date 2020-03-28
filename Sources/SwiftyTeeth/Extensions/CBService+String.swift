//
//  CBService.swift
//  SwiftyTeeth
//
//  Created by Suresh Joshi on 2017-02-05.
//
//

import CoreBluetooth

internal extension CBService {
    func equals(_ uuidString: String) -> Bool {
        return self.uuid.uuidString.lowercased() == uuidString.lowercased()
    }
}

internal extension Array where Element: CBService {
    func find(uuidString: String) -> CBService? {
        return self.first(where: {$0.equals(uuidString)})
    }
}
