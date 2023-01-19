//
//  Codable+extension.swift
//  
//
//  Created by Tomasz on 19/01/2023.
//

import Foundation

extension Encodable {
    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(self) else {
            return "{}"
        }
        return String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/") ?? "{}"
    }
}
