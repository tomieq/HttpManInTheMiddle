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
    private var websocketSessions: [WebSocketSession] = []

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
        self.server.get["/"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            do {
                let template = Template(raw: try String(contentsOfFile: "\(self.dynamicDir)/index.tpl.html"))
                return template.asResponse()
            } catch {
                Logger.e(self.logTag, "Error \(error)")
                return .internalServerError()
            }
        }
        
        self.server.post["/deploy"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            struct Form: Decodable {
                let localPort: UInt16
                let destinationUrl: String
            }
            guard let form: Form = try? request.formData.decode() else {
                return .ok(.js("uiShowError('Missing fields')"))
            }
            Logger.v(self.logTag, "Deploying new proxy server on port \(form.localPort) to \(form.destinationUrl)")
            let server = ProxyServer(destinationServer: form.destinationUrl)
            server.trafficSink = self.trafficDataHandler(_:)
            server.start(port: form.localPort)
            self.proxyServers[form.localPort] = server
            return .ok(.js("uiShowSuccess('Server deployed!'); loadHtmlThenRunScripts('/deployList', [], '#mainContent')"))
        }
        
        self.server.get["/terminate"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            guard let portString = request.queryParams.get("port"), let port = UInt16(portString) else {
                return .ok(.js("uiShowError('Missing port')"))
            }
            Logger.v(self.logTag, "Terminating proxy server on port \(port)")
            self.proxyServers[port]?.stop()
            self.proxyServers[port] = nil
            return .ok(.js("uiShowSuccess('Server terminated!'); loadHtmlThenRunScripts('/deployList', [], '#mainContent')"))
        }
        
        self.server.get["/delay"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            struct Params: Decodable {
                let port: UInt16
                let delay: TimeInterval
            }
            guard let params: Params = try? request.queryParams.decode() else {
                return .ok(.js("uiShowError('Missing port/delay params')"))
            }
            Logger.v(self.logTag, "Updating proxy server on port \(params.port) with delay: \(params.delay)")
            self.proxyServers[params.port]?.delay = params.delay
            return .ok(.js("uiShowSuccess('Server`s delay updated!');"))
        }
        
        self.server.get["/deployForm"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            do {
                let template = Template(raw: try String(contentsOfFile: "\(self.dynamicDir)/deployForm.tpl.html"))
                return template.asResponse()
            } catch {
                Logger.e(self.logTag, "Error \(error)")
                return .internalServerError()
            }
        }
        
        self.server.get["/deployList"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            do {
                let template = Template(raw: try String(contentsOfFile: "\(self.dynamicDir)/deployList.tpl.html"))
                for proxy in self.proxyServers {
                    template.assign(variables: ["port": "\(proxy.key)",
                                                "counter": "\(proxy.value.stats)",
                                                "delay": "\(Int(proxy.value.delay ?? 0))",
                                                "url": proxy.value.destinationServer], inNest: "entry")
                }
                return template.asResponse()
            } catch {
                Logger.e(self.logTag, "Error \(error)")
                return .internalServerError()
            }
        }
        
        self.server.get["/traffic"] = { [unowned self] request, headers in
            request.disableKeepAlive = true
            do {
                let template = Template(raw: try String(contentsOfFile: "\(self.dynamicDir)/trafficList.tpl.html"))
                return template.asResponse()
            } catch {
                Logger.e(self.logTag, "Error \(error)")
                return .internalServerError()
            }
        }
        
        self.server.get["/websocket.js"] = { [unowned self] request, _ in
            request.disableKeepAlive = true
            do {
                let template = Template(raw: try String(contentsOfFile: "\(self.dynamicDir)/websocket.js"))
                template.assign(variables: ["url": "ws://127.0.0.1:\((try? server.port()) ?? 0)/websocket"])
                return .ok(.js(template.output()))
            } catch {
                Logger.e(self.logTag, "Error \(error)")
                return .internalServerError()
            }
        }

        self.server.get["/websocket"] = websocket(text: { (session, text) in
        }, binary: { (session, binary) in
        }, pong: { (_, _) in
            // Got a pong frame
        }, connected: { [unowned self] session in
            Logger.v(self.logTag, "New websocket client connected")
            self.websocketSessions.append(session)
        }, disconnected: { [unowned self] session in
            Logger.v(self.logTag, "New websocket client disconnected")
            self.websocketSessions.remove(object: session)
        })

        self.server.notFoundHandler = { [unowned self] request, responseHeaders in
            request.disableKeepAlive = true
            let filePath = "\(self.staticDir)\(request.path)"
            try HttpFileResponse.with(absolutePath: filePath)
            Logger.e(self.logTag, "File `\(filePath)` doesn't exist")
            return .notFound()
        }
    }

    private func trafficDataHandler(_ data: TrafficData) {
        for session in self.websocketSessions {
            session.writeText(data.json)
        }
    }
}

