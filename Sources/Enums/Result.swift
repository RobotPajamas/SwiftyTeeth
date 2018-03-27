//
//  Result.swift
//  SwiftyTeeth iOS
//
//  Created by Suresh Joshi on 2018-03-27.
//

public enum Result<Value> {
    case success(Value)
    case failure(Error)
}

extension Result {
    public init(value: Value) {
        self = .success(value)
    }
    
    public init(error: Error) {
        self = .failure(error)
    }
}

extension Result {
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    public var isFailure: Bool {
        return !isSuccess
    }
}
