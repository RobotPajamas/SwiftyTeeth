//
//  OperationQueue.swift
//  SwiftyTeeth iOS
//
//  Created by Suresh Joshi on 2018-03-27.
//

import Foundation

extension OperationQueue: SwiftyQueue {
    
    var items: [Operation] {
        return operations
    }
    
    func pushBack(_ item: Operation) {
        Log(v: "SwiftyQueue: Adding item to existing \(items.count) items in queue")
        self.addOperation(item)
    }
    
    func cancelAll() {
        Log(v: "SwiftyQueue: Cancelling all \(items.count) items in queue")
        self.cancelAllOperations()
    }
    
    
}
