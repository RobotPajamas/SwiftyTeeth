//
//  ScopingFunctions.swift
//  https://kotlinlang.org/docs/scope-functions.html
//
//  Created by SJ on 2022-12-16.
//

import Foundation

protocol ScopingFunctions {}

extension ScopingFunctions {

    /// The context object is available as a receiver (this). The return value is the object itself.
    /// Use apply for code blocks that don't return a value and mainly operate on the members of the receiver object.
    /// The common case for apply is the object configuration. Such calls can be read as "apply the following assignments to the object."
    ///
    /// let adam = Person("Adam").apply {
    ///     age = 32
    ///     city = "London"
    /// }
    /// print(adam)
    @inline(__always) func apply(block: (Self) -> Void) -> Self {
        block(self)
        return self
    }

    /// A non-extension function: the context object is passed as an argument, but inside the lambda, it's available as a receiver (this). The return value is the lambda result.
    /// We recommend with for calling functions on the context object without providing the lambda result. In the code, with can be read as "with this object, do the following."
    ///
    /// let numbers = ["one", "two", "three"]
    /// with(numbers) {
    ///     print("'with' is called with argument \($0)")
    ///     print("It contains \(count) elements")
    /// }
    /// // TODO: Is this actually "let"?
    @inline(__always) func with<R>(block: (Self) -> R) -> R {
        return block(self)
    }
}

extension NSObject: ScopingFunctions {}
