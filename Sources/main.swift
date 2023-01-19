import Foundation
import Dispatch

let webServer = WebServer(workingDir: FileManager.default.currentDirectoryPath)
webServer.start(port: 80)

dispatchMain()
