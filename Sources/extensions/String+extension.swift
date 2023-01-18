//
//  String+extension.swift
//  
//
//  Created by Tomasz on 18/01/2023.
//

import Foundation

extension String {
    func subString(_ from: Int,_ to: Int)-> String{
        if (self.count < to){
            return self
        }
        let start = self.index(self.startIndex, offsetBy: from)
        let end = self.index(self.startIndex, offsetBy: to)
        let range = start..<end
        return String (self[range])
    }
}

extension String {
    var prettyJSON: String {
        guard let origData = self.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: origData, options: []),
              let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
              let string = String(data: data, encoding: .utf8) else {
            return self
        }
        return string
    }
}
