//
//  OperationQueue.swift
//  SwiftyTeeth iOS
//
//  Created by Suresh Joshi on 2018-03-27.
//

import Foundation

extension OperationQueue: SwiftyQueue {
    
    func pushBack(item: QueueItem) {
        self.addOperation(item)
    }
    
    func cancelAll() {
        self.cancelAllOperations()
    }
    
    
}
