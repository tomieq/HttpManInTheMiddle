//
//  Optional+extension.swift
//  
//
//  Created by Tomasz on 18/01/2023.
//

import Foundation

extension Optional where Wrapped: CustomStringConvertible {
    public var readable: String {
        switch self {
        case .some(let value):
            return value.description
        case .none:
            return "nil"
        }
    }
}

extension Optional {
    var isNil: Bool {
        switch self {
        case .none:
            return true
        case .some:
            return false
        }
    }

    var notNil: Bool {
        !self.isNil
    }
}
