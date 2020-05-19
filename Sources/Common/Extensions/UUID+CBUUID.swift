//
//  UUID+CBUUID.swift
//  SwiftyTeeth
//
//  Created by SJ on 2020-03-26.
//

import CoreBluetooth
import Foundation

//extension CBUUID {
//    init?(uuid: UUID) {
//        self.init
//    }
//}

extension UUID {
    init?(cbuuid: CBUUID) {
        self.init(uuidString: cbuuid.uuidString)
    }
}
