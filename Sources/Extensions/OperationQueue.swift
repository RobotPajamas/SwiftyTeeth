//
//  OperationQueue.swift
//  SwiftyTeeth iOS
//
//  Created by Suresh Joshi on 2018-03-27.
//

import Foundation

extension OperationQueue: SwiftyQueue {
    
    var items: [QueueItem<Any>] {
        return self.operations.map({ (operation) -> QueueItem<Any> in
            return operation as! QueueItem<Any>
        })
    }
    
    func pushBack(_ item: QueueItem<Any>) {
        self.addOperation(item)
    }
    
    func cancelAll() {
        self.cancelAllOperations()
    }
    
    
}
