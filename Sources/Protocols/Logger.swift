//
//  Logger.swift
//  SwiftyTeeth
//
//  Created by Suresh Joshi on 2017-07-05.
//
//

public protocol Logger {
    func verbose(_ message: String)
    func debug(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}

public func Log(v message: String, path: String = #file, function: String = #function, line: Int = #line) {
    swiftyTeethLogger?.verbose(message)
}

public func Log(d message: String, path: String = #file, function: String = #function, line: Int = #line) {
    swiftyTeethLogger?.debug(message)
}

public func Log(i message: String, path: String = #file, function: String = #function, line: Int = #line) {
    swiftyTeethLogger?.info(message)
}

public func Log(w message: String, path: String = #file, function: String = #function, line: Int = #line) {
    swiftyTeethLogger?.warning(message)
}

public func Log(e message: String, path: String = #file, function: String = #function, line: Int = #line) {
    swiftyTeethLogger?.error(message)
}
