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
        Log(v: "SwiftyQueue: Now there are \(items.count) items in queue")
        for item in items {
            Log(v: "SwiftyQueue: \(item.name ?? "(none)") is in the queue")
        }
    }
    
    func cancelAll() {
        Log(v: "SwiftyQueue: Cancelling all \(items.count) items in queue")
        for item in items {
            Log(v: "SwiftyQueue: About to be cancelled \(item.name ?? "(none)")")
        }
        self.cancelAllOperations()
    }
}
