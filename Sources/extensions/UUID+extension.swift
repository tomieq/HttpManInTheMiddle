//
//  UUID+extension.swift
//  
//
//  Created by Tomasz on 18/01/2023.
//

import Foundation

extension UUID {
    var shortID: String {
        self.uuidString.subString(0, 8).lowercased()
    }
}
