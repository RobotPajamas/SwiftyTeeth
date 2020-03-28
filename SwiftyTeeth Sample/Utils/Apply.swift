//
//  Apply.swift
//  SwiftyTeeth Sample
//
//  Created by SJ on 2020-03-28.
//

import Foundation

public protocol Apply {
}

public extension Apply where Self: Any {

    /// Makes it available to set properties with closures just after initializing.
    ///
    ///     let label = UILabel().with {
    ///       $0.textAlignment = .center
    ///       $0.textColor = UIColor.black
    ///       $0.text = "Hello, World!"
    ///     }
    func apply(_ block: (Self) -> Void) -> Self {
        // https://github.com/devxoul/Then
        block(self)
        return self
    }
}

extension NSObject: Apply {
}
