//
//  TrafficData.swift
//  
//
//  Created by Tomasz on 19/01/2023.
//

import Foundation

class TrafficData: Codable {
    let id: String
    let path: String
    let method: String
    var requestHeaders: [String: String] = [:]
    var requestBody: String = ""
    var error: String?
    var responseCode: Int?
    var responseHeaders: [String: String] = [:]
    var responseBody: String?

    init(id: String, path: String, method: String) {
        self.id = id
        self.path = path
        self.method = method
    }
}
