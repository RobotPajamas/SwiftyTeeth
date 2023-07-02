//
//  logger.swift
//
//
//  Created by SJ on 2023-07-02.
//

import Foundation
import SwiftyTeeth

final class MyLogger: Logger {
    func verbose(_ message: String) {
        print("V: " + message)
    }
    func debug(_ message: String) {
        print("D: " + message)
    }
    func info(_ message: String) {
        print("I: " + message)
    }
    func warning(_ message: String) {
        print("W: " + message)
    }
    func error(_ message: String) {
        print("E: " + message)
    }
}
