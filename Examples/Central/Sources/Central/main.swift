//
//  main.swift
//
//
//  Created by SJ on 2023-07-02.
//

import Foundation
import SwiftyTeeth

SwiftyTeeth.logger = MyLogger()
let instance = SwiftyTeeth.shared

instance.stateChangedHandler = { (state) in
    print("Current Bluetooth state is: \(state)")
    if state == .poweredOn {
        print("Starting scan for 10 seconds")
        instance.scan(for: 10.0) { device in
            print("Found \(device.name) (\(device.id))")
        } complete: { devices in
            print("Done scanning - discovered \(devices.count) nearby devices...")
            print(devices.map { $0.name })
            exit(0)
        }
    }
}


RunLoop.main.run()
