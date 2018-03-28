//
//  QueueItem.swift
//  SwiftyTeeth iOS
//
//  Created by Suresh Joshi on 2018-03-27.
//

import Foundation

private enum State: String {
    case none = "None"
    case ready = "Ready"
    case executing = "Executing"
    case finishing = "Finishing" // On route to finished, but haven't notified Queue
    case finished = "Finished"
    
    fileprivate var keyPath: String { return "is" + self.rawValue }
}

public class QueueItem: Operation {
    
    override public var isAsynchronous: Bool { return true }
    override public var isExecuting: Bool { return state == .executing }
    override public var isFinished: Bool { return state == .finished }
    
    fileprivate var state = State.ready {
        willSet {
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
        }
        didSet {
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    
    let timeout: TimeInterval
    let doOnFailure: FailureHandler
    
    public init(timeout: TimeInterval = 0.0,
                         doOnFailure: FailureHandler = .nothing,
                         priority: QueuePriority = .normal,
                         completion: (() -> Void)? = nil) {
        self.timeout = timeout // TODO: Does nothing
        self.doOnFailure = doOnFailure // TODO: Does nothing
        super.init()
        self.queuePriority = priority
        self.completionBlock = completion
    }
    
    public override func main() {
        guard isCancelled == false else {
            finish()
            return
        }
        
        execute()
    }
    
    public func finish() {
        state = .finished
    }
}

// To be overridden
extension QueueItem: Queueable {
    
    func execute() {
        finish()
    }
}

//// MARK: Soul-crushing-ness
//internal extension QueueItem {
//    @objc dynamic class func keyPathsForValuesAffectingIsCancelled() -> Set<NSObject> {
//        return ["state" as NSObject]
//    }
//
//    @objc dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
//        return ["state" as NSObject]
//    }
//
//    @objc dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
//        return ["state" as NSObject]
//    }
//
//    //    @objc dynamic class func keyPathsForValuesAffectingIsCancelled() -> Set<NSObject> {
//    //        return ["state" as NSObject]
//    //    }
//}

