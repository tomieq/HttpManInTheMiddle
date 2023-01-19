//
//  Template+HttpResponse.swift
//  
//
//  Created by Tomasz on 19/01/2023.
//

import Foundation
import Swifter

extension Template {
    func asResponse() -> HttpResponse {
        if let data = output().data(using: .utf8) {
            return .raw(200, "OK") { writer in
                try? writer.write(data)
            }
        }
        return .noContent
    }
}
