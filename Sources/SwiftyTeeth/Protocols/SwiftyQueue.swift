//
//  SwiftyQueue.swift
//  SwiftyTeeth iOS
//
//  Created by Suresh Joshi on 2018-03-27.
//

import Foundation

internal protocol SwiftyQueue {
    var items: [Operation] {get}
    
    func pushBack(_ item: Operation)
    func cancelAll()
}

public enum FailureHandler {
    case nothing
    case retry
    case reschedule
}

internal protocol Queueable {
    var timeout: TimeInterval {get}
    var doOnFailure: FailureHandler {get}
    // priority
    
    func execute()
    func cancel()
}
