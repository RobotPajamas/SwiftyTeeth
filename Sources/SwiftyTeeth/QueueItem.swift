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

public class QueueItem<T>: Operation {
    public typealias CallbackBlock = (Result<T, Error>, () -> Void) -> Void
    public typealias ExecutionBlock = ((Result<T, Error>) -> Void) -> Void
    
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
            mutex.wait()
        }
        didSet {
            mutex.signal()
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    
    let timeout: TimeInterval = 0.0
    let doOnFailure: FailureHandler = .nothing
    
    private let execution: ExecutionBlock?
    private let callback: CallbackBlock?
    
    private let mutex = DispatchSemaphore(value: 1)
    
    public init(
        name: String? = nil,
        //delay: TimeInterval = 0.0, // When the task is kicked off, start running after 'delay'
//        timeout: TimeInterval = 0.0, // After starting, give up after 'timeout'
//        doOnFailure: FailureHandler = .nothing, // Retry/reschedule on failure
        priority: QueuePriority = .normal,
        execution: ExecutionBlock? = nil, // TODO: Does this being nil make sense??
        callback: CallbackBlock? = nil) {
        
        self.execution = execution
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

    public override func cancel() {
        super.cancel()
        done()
    }
    
    // Call this after Execute is completed to allow Queue to continue
    public func done() {
        state = .finished
    }
}

// To be overridden
extension QueueItem: Queueable {
    
    func execute() {
        Log(v: "QueueItem: Executing \(self.name ?? "(none)")")
        if let execution = execution {
            execution { (result) in
                // Allow an early exit from the task if execution was a failure
                switch result {
                case .failure:
                    notify(result)
                default:
                    break
                }
            }
        } else {
            done()
        }
    }
    
    func notify(_ result: Result<T, Error>) {
        Log(v: "QueueItem: Notifying \(self.name ?? "(none)")")
        if let cb = callback {
            cb(result) {
                done()
            }
        } else {
            done()
        }
    }
}
