//
//  Logger.swift
//  SwiftyTooth
//
//  Created by Suresh Joshi on 2017-07-05.
//
//

public func Log(v message: String, tag: String = "SwiftyTooth", path: String = #file, function: String = #function, line: Int = #line) {
    swiftyToothLogger?.verbose("\(tag): \(message)")
}

public func Log(d message: String, tag: String = "SwiftyTooth", path: String = #file, function: String = #function, line: Int = #line) {
    swiftyToothLogger?.debug("\(tag): \(message)")
}

public func Log(i message: String, tag: String = "SwiftyTooth", path: String = #file, function: String = #function, line: Int = #line) {
    swiftyToothLogger?.info("\(tag): \(message)")
}

public func Log(w message: String, tag: String = "SwiftyTooth", path: String = #file, function: String = #function, line: Int = #line) {
    swiftyToothLogger?.warning("\(tag): \(message)")
}

public func Log(e message: String, tag: String = "SwiftyTooth", path: String = #file, function: String = #function, line: Int = #line) {
    swiftyToothLogger?.error("\(tag): \(message)")
}
