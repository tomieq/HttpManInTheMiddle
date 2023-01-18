//
//  WebServer.swift
//  
//
//  Created by Tomasz on 18/01/2023.
//

import Foundation
import Swifter

public class WebServer {
    private let logTag = "👁️ Spy"
    private let server: HttpServer
    private let destinationServer: String
    private static let requestCounterSemaphone = DispatchSemaphore(value : 1)
    private static var requestCounter = 0

    public init(destinationServer: String) {
        self.server = HttpServer()
        self.destinationServer = destinationServer.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.initEndpoints()
    }

    public func start(port: UInt16) {
        do {
            try self.server.start(port, forceIPv4: true)
            Logger.v(self.logTag, "HttpProxy has started on port = \(try self.server.port()), destinationServer = \(self.destinationServer)")
        } catch {
            Logger.e(self.logTag, "HttpProxy start error: \(error)")
        }
    }

    private func forwardRequest(originalRequest: HttpRequest, responseHeaders: HttpResponseHeaders) -> HttpResponse {
        let sem = DispatchSemaphore(value : 0)
        var destinationPath = "\(self.destinationServer)\(originalRequest.path)"
        let paramQuery = originalRequest.queryParams.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
        if !paramQuery.isEmpty {
            destinationPath.append("?")
            destinationPath.append(paramQuery)
        }
        
        let reqID = self.getRequestID()

        var finalResponse: HttpResponse = .serviceUnavailable
        if let url = URL(string: destinationPath) {
            Logger.v(self.logTag, "[\(reqID)] Request forward url: \(originalRequest.method) \(destinationPath)")
            let headersString = originalRequest.headers.map { "\($0.key) = \($0.value)" }.joined(separator: "\n\t")
            Logger.v(self.logTag, "[\(reqID)] Request headers: \n{\n\t\(headersString)\n}")
            let body = Data(originalRequest.body)
            if let bodyString = String(data: body, encoding: .utf8) {
                if bodyString.isEmpty {
                    Logger.v(self.logTag, "[\(reqID)] Request body: nil")
                } else {
                    Logger.v(self.logTag, "[\(reqID)] Request body: \n\(bodyString.prettyJSON)")
                }
            } else {
                Logger.v(self.logTag, "[\(reqID)] Request body: binary \(self.readableSize(size: body.count))")
            }
            var request = URLRequest(url: url)
            request.httpMethod = originalRequest.method.rawValue
            request.allHTTPHeaderFields = self.prepareHttpHeaders(original: originalRequest.headers)
            
            request.httpBody = Data(originalRequest.body)
            URLSession.shared.dataTask(with: request) { [weak sem, weak self] data, response, error in
                if let error = error {
                    Logger.v(self?.logTag, "[\(reqID)] Response error: \(error)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    let responseCode = httpResponse.statusCode
                    Logger.v(self?.logTag, "[\(reqID)] Response code: \(responseCode)")
                    let headersString = httpResponse.allHeaderFields.map { "\($0.key) = \($0.value)" }.joined(separator: "\n\t")
                    Logger.v(self?.logTag, "[\(reqID)] Response headers: \n{\n\t\(headersString)\n}")
                    
                    httpResponse.allHeaderFields.forEach {
                        if let key = $0.key as? String, let value = $0.value as? String {
                            responseHeaders.addHeader(key, value)
                        }
                    }
                    if let body = data {
                        if let bodyString = String(data: body, encoding: .utf8) {
                            if bodyString.isEmpty {
                                Logger.v(self?.logTag, "[\(reqID)] Response body: nil")
                            } else {
                                Logger.v(self?.logTag, "[\(reqID)] Response body: \n\(bodyString.prettyJSON)")
                            }
                        } else {
                            Logger.v(self?.logTag, "[\(reqID)] Response body: binary \(self?.readableSize(size: body.count) ?? "")")
                        }
                    }
                    switch responseCode {
                    case 200:
                        finalResponse = .ok(.data(data ?? Data()))
                    case 202:
                        finalResponse = .accepted(data.isNil ? nil : .data(data!))
                    case 404:
                        finalResponse = .notFound(data.isNil ? nil : .data(data!))
                    default:
                        break
                    }
                }
                sem?.signal()
            }.resume()
        }
        _ = sem.wait(timeout:.now() + 15)
        return finalResponse
    }

    private func initEndpoints() {

        self.server.middleware.append { [weak self] originalRequest, responseHeaders in
            guard let self = self else {
                return .internalServerError()
            }
            return self.forwardRequest(originalRequest: originalRequest, responseHeaders: responseHeaders)
        }
    }
    
    private func prepareHttpHeaders(original: [String: String]) -> [String: String] {
        var headers = original
        headers["host"] = nil
        headers["content-length"] = nil
        return headers
    }

    private func readableSize(size: Int) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        return String(format: "%4.1f %@", convertedValue, tokens[multiplyFactor])
    }
    
    private func getRequestID() -> String {
        Self.requestCounterSemaphone.wait()
        Self.requestCounter += 1
        var id = "\(Self.requestCounter)"
        while id.count < 3 {
            id = "0\(id)"
        }
        Self.requestCounterSemaphone.signal()
        return id
    }
}
