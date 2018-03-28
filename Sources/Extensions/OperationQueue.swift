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
        self.addOperation(item)
    }
    
    func cancelAll() {
        self.cancelAllOperations()
    }
    
    
}
