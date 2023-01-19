//
//  Template.swift
//  
//
//  Created by Tomasz on 19/01/2023.
//

import Foundation

class Template {
    private var content: String = ""
    private let contentCache: String
    private var nestedContent: [String: String] = [:]
    private let nestPattern = #"(\[START)[(\s)+]([a-zA-Z0-9-_]+)\](.+?)(\[END\s[a-zA-Z0-9-_]+\])"#

    init(raw: String) {
        self.contentCache = raw
        self.reset()
    }

    func reset() {
        self.content = self.contentCache
        self.nestedContent = [:]

        var nests = [String: String]()
        if let regex = try? NSRegularExpression(pattern: nestPattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(location: 0, length: content.utf16.count)
            regex.enumerateMatches(in: self.content, options: [], range: range) { match, _, _ in
                guard let match = match else { return }
                guard match.numberOfRanges == 5 else { return }

                let nestName = self.subContent(from: match.range(at: 2))
                let nestContent = self.subContent(from: match.range(at: 3))
                self.nestedContent[nestName] = nestContent

                let nestStart = match.range(at: 1).lowerBound
                let nestEnd = match.range(at: 4).lowerBound + match.range(at: 4).length - 1
                nests[nestName] = self.subContent(from: nestStart, to: nestEnd)
            }
        }
        for txt in nests {
            self.content = self.content.replacingOccurrences(of: txt.value, with: self.nestTag(txt.key))
        }
    }

    private func subContent(from range: NSRange) -> String {
        let start = range.lowerBound
        let end = range.lowerBound + range.length - 1
        return self.subContent(from: start, to: end)
    }

    private func subContent(from: Int, to: Int) -> String {
        let start = self.content.index(self.content.startIndex, offsetBy: from)
        let end = self.content.index(self.content.startIndex, offsetBy: to)
        return "\(self.content[start...end])"
    }

    private func cleanOutput() {
        let pattern = "(\\{[a-zA-Z0-9-_]+\\})"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: content.utf16.count)
            self.content = regex.stringByReplacingMatches(in: self.content, options: [], range: range, withTemplate: "")
        }
    }

    private func nestTag(_ name: String) -> String {
        return "{nest-\(name)}"
    }

    func assign(variables: [String: String]?, inNest nestName: String) {
        if let nestContent = nestedContent[nestName] {
            var content = "\(nestContent)"
            for variable in variables ?? [:] {
                content = content.replacingOccurrences(of: "{\(variable.key)}", with: variable.value)
            }
            let nestTag = self.nestTag(nestName)
            self.content = self.content.replacingOccurrences(of: nestTag, with: "\(content)\(nestTag)")
        }
    }

    func assign(variables: [String: String]) {
        for variable in variables {
            self.content = self.content.replacingOccurrences(of: "{\(variable.key)}", with: variable.value)
        }
    }

    func output() -> String {
        self.cleanOutput()
        return self.content
    }

    static func htmlNode(type: String, attributes: [String: String] = [:], content: String = "") -> String {
        return "<\(type) \(attributes.map { "\($0.key)=\"\($0.value)\"" }.joined(separator: " "))>\(content)</\(type)>"
    }
}
