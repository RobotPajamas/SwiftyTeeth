//
//  Service.swift
//  SwiftyTeeth
//
//  Created by SJ on 2020-03-02.
//

import Foundation

public struct Service {
    public let uuid: UUID
    public let characteristics: [Characteristic]
    
    public init(uuid: UUID, characteristics: [Characteristic]) {
        self.uuid = uuid
        self.characteristics = characteristics
    }
}
