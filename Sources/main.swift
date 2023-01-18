import Foundation
import Dispatch


let destinationServer1 = "https://example.com/"
let server1 = WebServer(destinationServer: destinationServer1)
server1.start(port: 8080)


let destinationServer2 = "https://company.org/"
let server2 = WebServer(destinationServer: destinationServer2)
server2.start(port: 8081)

dispatchMain()
