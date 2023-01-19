//
//  Array+extension.swift
//  
//
//  Created by Tomasz on 19/01/2023.
//

import Foundation

extension Array where Element: Equatable {
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = firstIndex(of: object) {
            self.remove(at: index)
        }
    }
}
