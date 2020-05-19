//
//  Logger.swift
//  SwiftyTeeth
//
//  Created by SJ on 2020-05-18.
//

public protocol Logger {
    func verbose(_ message: String)
    func debug(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}
