//
//  SwiftyTeethable.swift
//  SwiftyTeeth
//
//  Created by Basem Emara on 10/27/16.
//
//

import Foundation

/// Protocol used to enhance arbitrary objects.
public protocol SwiftyTeethable {

}

extension SwiftyTeethable {
    
    /// Central and peripheral bluetooth manager.
    public var swiftyTeeth: SwiftyTeeth {
        return SwiftyTeeth.shared
    }
}
