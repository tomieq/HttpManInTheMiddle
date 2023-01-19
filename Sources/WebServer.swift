//
//  WebServer.swift
//  
//
//  Created by Tomasz on 19/01/2023.
//

import Foundation
import Swifter

class WebServer {
    private let logTag = "🧠 WebServer"
    private let server: HttpServer
    private let workingDir: String
    private var staticDir: String { "\(self.workingDir)/Resources/static" }
    private var dynamicDir: String { "\(self.workingDir)/Resources/dynamic" }
    private var proxyServers: [UInt16: ProxyServer] = [:]

    init(workingDir: String) {
        self.server = HttpServer()
        self.workingDir = workingDir
        self.initEndpoints()
    }

    func start(port: UInt16) {
        do {
            try self.server.start(port, forceIPv4: true)
            Logger.v(self.logTag, "Started on port = \(try self.server.port()), workingDir = \(self.workingDir)")
        } catch {
            Logger.e(self.logTag, "Start error: \(error)")
        }
    }


    private func initEndpoints() {
        self.server.GET["/"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            do {
                let template = Template(raw: try String(contentsOfFile: "\(self.dynamicDir)/index.tpl.html"))
                return template.asResponse()
            } catch {
                Logger.e(self.logTag, "Error \(error)")
                return .internalServerError()
            }
        }
        
        self.server.POST["/deploy"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            let formData = request.flatFormData()
            guard let portString = formData["localPort"], let destinationUrl = formData["destinationUrl"],
                  let port = UInt16(portString) else {
                Logger.e(self.logTag, "Missing form fields")
                return .ok(.javaScript("uiShowError('Missing fields')"))
            }
            Logger.v(self.logTag, "Deploying new proxy server on port \(port) to \(destinationUrl)")
            let server = ProxyServer(destinationServer: destinationUrl)
            server.start(port: port)
            self.proxyServers[port] = server
            return .ok(.javaScript("uiShowSuccess('Server deployed!'); loadHtmlThenRunScripts('/deployList', [], '#mainContent')"))
        }
        
        self.server.GET["/terminate"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            guard let portString = request.queryParam("port"), let port = UInt16(portString) else {
                return .ok(.javaScript("uiShowError('Missing port')"))
            }
            Logger.v(self.logTag, "Terminating proxy server on port \(port)")
            self.proxyServers[port]?.stop()
            self.proxyServers[port] = nil
            return .ok(.javaScript("uiShowSuccess('Server terminated!'); loadHtmlThenRunScripts('/deployList', [], '#mainContent')"))
        }
        
        self.server.GET["/deployForm"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            do {
                let template = Template(raw: try String(contentsOfFile: "\(self.dynamicDir)/deployForm.tpl.html"))
                return template.asResponse()
            } catch {
                Logger.e(self.logTag, "Error \(error)")
                return .internalServerError()
            }
        }
        
        self.server.GET["/deployList"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            do {
                let template = Template(raw: try String(contentsOfFile: "\(self.dynamicDir)/deployList.tpl.html"))
                for proxy in self.proxyServers {
                    template.assign(variables: ["port": "\(proxy.key)",
                                                "counter": "\(proxy.value.stats)",
                                                "url": proxy.value.destinationServer], inNest: "entry")
                }
                return template.asResponse()
            } catch {
                Logger.e(self.logTag, "Error \(error)")
                return .internalServerError()
            }
        }
        
        self.server.notFoundHandler = { [unowned self] request, responseHeaders in
            request.disableKeepAlive = true
            let filePath = "\(self.staticDir)\(request.path)"
            if FileManager.default.fileExists(atPath: filePath) {
                guard let file = try? filePath.openForReading() else {
                    Logger.e(self.logTag, "Could not open `\(filePath)`")
                    return .notFound()
                }
                let mimeType = filePath.mimeType()
                responseHeaders.addHeader("Content-Type", mimeType)

                if let attr = try? FileManager.default.attributesOfItem(atPath: filePath),
                   let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                    responseHeaders.addHeader("Content-Length", String(fileSize))
                }

                return .raw(200, "OK", { writer in
                    try writer.write(file)
                    file.close()
                })
            }
            Logger.e(self.logTag, "File `\(filePath)` doesn't exist")
            return .notFound()
        }
    }

}

