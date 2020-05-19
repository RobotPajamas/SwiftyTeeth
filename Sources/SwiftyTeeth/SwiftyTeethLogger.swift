//
//  Logger.swift
//  SwiftyTeeth
//
//  Created by Suresh Joshi on 2017-07-05.
//
//

public func Log(v message: String, tag: String = "SwiftyTeeth", path: String = #file, function: String = #function, line: Int = #line) {
    swiftyTeethLogger?.verbose("\(tag): \(message)")
}

public func Log(d message: String, tag: String = "SwiftyTeeth", path: String = #file, function: String = #function, line: Int = #line) {
    swiftyTeethLogger?.debug("\(tag): \(message)")
}

public func Log(i message: String, tag: String = "SwiftyTeeth", path: String = #file, function: String = #function, line: Int = #line) {
    swiftyTeethLogger?.info("\(tag): \(message)")
}

public func Log(w message: String, tag: String = "SwiftyTeeth", path: String = #file, function: String = #function, line: Int = #line) {
    swiftyTeethLogger?.warning("\(tag): \(message)")
}

public func Log(e message: String, tag: String = "SwiftyTeeth", path: String = #file, function: String = #function, line: Int = #line) {
    swiftyTeethLogger?.error("\(tag): \(message)")
}
