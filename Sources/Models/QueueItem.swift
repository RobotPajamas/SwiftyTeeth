//
//  QueueItem.swift
//  SwiftyTeeth iOS
//
//  Created by Suresh Joshi on 2018-03-27.
//

import Foundation

public typealias ExecutionBlock = (() -> Void)

private enum State: String {
    case none = "None"
    case ready = "Ready"
    case executing = "Executing"
    case finishing = "Finishing" // On route to finished, but haven't notified Queue
    case finished = "Finished"
    
    fileprivate var keyPath: String { return "is" + self.rawValue }
}

public class QueueItem<T>: Operation {
    public typealias CallbackBlock = ((Result<T>) -> Void)
    
    //
    @available(*, deprecated, message: "Don't use this")
    override open var completionBlock: (() -> Void)? {
        get {
            return nil
        }
        set {
            fatalError("completionBlock has some funky behaviour regarding threading and execution - prefer using regular init")
        }
    }
    
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
    
    let timeout: TimeInterval = 0.0
    let doOnFailure: FailureHandler = .nothing
    let execution: ExecutionBlock?
    let callback: CallbackBlock?
    
    public init(
        name: String? = nil,
//        timeout: TimeInterval = 0.0,
//        doOnFailure: FailureHandler = .nothing,
        priority: QueuePriority = .normal,
        execution: ExecutionBlock? = nil,
        callback: CallbackBlock? = nil) {
//        self.timeout = timeout
//        self.doOnFailure = doOnFailure
        self.execution = execution // TODO: Maybe use something else
        self.callback = callback
        super.init()
        self.name = name
        self.queuePriority = priority
    }
    
    public override func main() {
        guard isCancelled == false else {
            done()
            return
        }
        state = .executing
        execute()
    }
    
    // Call this after Execute is completed to allow Queue to continue
    public func done() {
        state = .finished
    }
}

// To be overridden
extension QueueItem: Queueable {
    
    func execute() {
//        preconditionFailure("This method must be overridden - ensure to call done() at the end")
        if let execution = execution {
            execution()
        } else {
            done()
        }
    }
}
