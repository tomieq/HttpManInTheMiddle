//
//  ProxyServer.swift
//  
//
//  Created by Tomasz on 18/01/2023.
//

import Foundation
import Swifter

class ProxyServer {
    private let logTag = "👁️: Proxy"
    private let server: HttpServer
    let destinationServer: String
    var stats = 0
    private static let requestCounterSemaphone = DispatchSemaphore(value : 1)
    private static var requestCounter = 0
    var trafficSink: ((TrafficData) -> Void)?
    var delay: TimeInterval? = nil

    init(destinationServer: String) {
        self.server = HttpServer()
        self.destinationServer = destinationServer.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.initEndpoints()
    }

    func start(port: UInt16) {
        do {
            try self.server.start(port, forceIPv4: true)
            Logger.v(self.logTag, "HttpProxy has started on port = \(try self.server.port()), destinationServer = \(self.destinationServer)")
        } catch {
            Logger.e(self.logTag, "HttpProxy start error: \(error)")
        }
    }
    
    func stop() {
        do {
            let port = try self.server.port()
            self.server.stop()
            Logger.v(self.logTag, "HttpProxy has stopped on port = \(port), destinationServer = \(self.destinationServer)")
        } catch {
            Logger.e(self.logTag, "HttpProxy stop error: \(error)")
        }
    }

    private func forwardRequest(originalRequest: HttpRequest, responseHeaders: HttpResponseHeaders) -> HttpResponse {
        var destinationPath = "\(self.destinationServer)\(originalRequest.path)"
        if let delay = self.delay {
            Logger.v(self.logTag, "Got new request to \(destinationPath), starting delay \(Int(delay))s")
            let semDelay = DispatchSemaphore(value : 0)
            _ = semDelay.wait(timeout:.now() + delay)
            Logger.e(self.logTag, "Delay finished")
        }
        let sem = DispatchSemaphore(value : 0)
        let paramQuery = originalRequest.queryParams.list.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
        if !paramQuery.isEmpty {
            destinationPath.append("?")
            destinationPath.append(paramQuery)
        }
        
        let reqID = self.getRequestID()
        var logBuffer = "Request \(reqID)\n------------------------------------------"

        let trafficData = TrafficData(id: reqID, path: destinationPath, method: originalRequest.method.rawValue)
        var finalResponse: HttpResponse = .serviceUnavailable
        if let url = URL(string: destinationPath) {
            logBuffer.append("\n\(originalRequest.method) \(destinationPath)")
            let headersString = originalRequest.headers.dict.map { "\($0.key) = \($0.value)" }.joined(separator: "\n\t")
            logBuffer.append("\n➡️: Request headers: \n{\n\t\(headersString)\n}")
            trafficData.requestHeaders = originalRequest.headers.dict
            let body = originalRequest.body.data
            if let bodyString = String(data: body, encoding: .utf8) {
                trafficData.requestBody = bodyString.prettyJSON
                if bodyString.isEmpty {
                    logBuffer.append("\n➡️: Request body: nil")
                } else {
                    logBuffer.append("\n➡️: Request body: \n\(bodyString.prettyJSON)")
                }
            } else {
                trafficData.requestBody = "binary \(self.readableSize(size: body.count))"
                logBuffer.append("\n➡️: Request body: binary \(self.readableSize(size: body.count))")
            }
            var request = URLRequest(url: url)
            request.httpMethod = originalRequest.method.rawValue
            request.allHTTPHeaderFields = self.prepareHttpHeaders(original: originalRequest.headers.dict)
            
            request.httpBody = originalRequest.body.data
            URLSession.shared.dataTask(with: request) { [weak sem, weak self] data, response, error in
                if let error = error {
                    logBuffer.append("\n➡️: Response error: \(error)")
                    trafficData.error = error.localizedDescription
                } else if let httpResponse = response as? HTTPURLResponse {
                    let responseCode = httpResponse.statusCode
                    trafficData.responseCode = responseCode
                    logBuffer.append("\n➡️: Response code: \(responseCode)")
                    let headersString = httpResponse.allHeaderFields.map { "\($0.key) = \($0.value)" }.joined(separator: "\n\t")
                    logBuffer.append("\n➡️: Response headers: \n{\n\t\(headersString)\n}")
                    httpResponse.allHeaderFields.forEach {
                        if let key = $0.key as? String, let value = $0.value as? String {
                            trafficData.responseHeaders[key] = value
                            responseHeaders.addHeader(key, value)
                        }
                    }
                    if let body = data {
                        if let bodyString = String(data: body, encoding: .utf8) {
                            trafficData.responseBody = bodyString.prettyJSON
                            if bodyString.isEmpty {
                                logBuffer.append("\n➡️: Response body: nil")
                            } else {
                                logBuffer.append("\n➡️: Response body: \n\(bodyString.prettyJSON)")
                            }
                        } else {
                            trafficData.responseBody = "binary \(self?.readableSize(size: body.count) ?? "")"
                            logBuffer.append("\n➡️: Response body: binary \(self?.readableSize(size: body.count) ?? "")")
                        }
                    }
                    switch responseCode {
                    case 200:   finalResponse = .ok(.data(data ?? Data()))
                    case 201:   finalResponse = .created(.data(data ?? Data()))
                    case 202:   finalResponse = .accepted(data.isNil ? nil : .data(data!))
                    case 204:   finalResponse = .noContent
                    case 400:   finalResponse = .badRequest(data.isNil ? nil : .data(data!))
                    case 401:   finalResponse = .unauthorized(data.isNil ? nil : .data(data!))
                    case 403:   finalResponse = .forbidden(data.isNil ? nil : .data(data!))
                    case 404:   finalResponse = .notFound(data.isNil ? nil : .data(data!))
                    case 406:   finalResponse = .notAcceptable(data.isNil ? nil : .data(data!))
                    case 500:   finalResponse = .internalServerError(data.isNil ? nil : .data(data!))
                    case 502:   finalResponse = .badGateway
                    default:
                        break
                    }
                }
                sem?.signal()
            }.resume()
        }
        _ = sem.wait(timeout:.now() + 15)
        self.trafficSink?(trafficData)
        Logger.v(self.logTag, logBuffer)
        return finalResponse
    }

    private func initEndpoints() {

        self.server.middleware.append { [unowned self] originalRequest, responseHeaders in
            self.stats += 1
            return self.forwardRequest(originalRequest: originalRequest, responseHeaders: responseHeaders)
        }
    }
    
    private func prepareHttpHeaders(original: [String: String]) -> [String: String] {
        var headers = original
        headers["host"] = nil
        headers["content-length"] = nil
        headers["Content-Length"] = nil
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
