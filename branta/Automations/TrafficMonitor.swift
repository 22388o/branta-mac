//
//  TrafficMonitor.swift
//  Branta
//
//  Created by Keith Gardner on 3/19/24.
//

import Cocoa
import Foundation

class TrafficMonitor: Automation {
    
    var tableView: NSTableView
    var parentPID: Int?
    var pids: Array<Int>                = []
    var connections: Array<Connection>  = []
    var walletName:String?
    weak var observer: DataFeedObserver?
    private var timer: Timer?

    // TODO - this should be a user preference.
    let CADENCE = 5.0
    
    let COLUMNS = [
        "PID": 0,
        "IP": 1,
    ]
    
    init(tableView: NSTableView, walletName: String) {
        self.walletName = walletName
        self.tableView = tableView
        super.init()
    }
    
    override func runDataFeed() {
        if SudoUtil.pw != nil {
            self.execute()
            observer?.dataFeedExecutionDidFinish(success: true)
        } else {
            SudoUtil.getPW { password in
                if password == nil {
                    self.observer?.dataFeedExecutionDidFinish(success: false)
                }
                else {
                    self.execute()
                    self.observer?.dataFeedExecutionDidFinish(success: true)
                }
            }
        }
    }
    
    func stopDataFeed() {
        timer?.invalidate()
        timer = nil
    }

    private
    
    func execute() {
        timer = Timer.scheduledTimer(withTimeInterval: CADENCE, repeats: true) { _ in

            DispatchQueue.main.async {
                // Get parentPID if not cached
                if self.parentPID == nil {
                    self.parentPID = PIDUtil.getParentPID(appName: self.walletName!)
                }
                
                // Get any children PIDs
                self.pids = PIDUtil.getChildPIDs(parentPID: self.parentPID!)
                
                // Get IPs from all PIDS combined
                self.getConnections()
                
                
                self.tableView.reloadData()
                self.observer?.dataFeedCount(count: self.connections.count)
            }
        }
        timer?.fire() // Optionally fire immediately
    }
    
    // Parse output of each PID. Not every PID talks over the network.
    func parseOutput(_ output: String) {
        if output == "" {
            return
        }
        
        let lines = output.components(separatedBy: "\n")
        
        for line in lines {
            let processedLine = line.removeExtraSpaces()
            let components = processedLine.components(separatedBy: .whitespaces)

            if components.count > 8 && components[0] != "COMMAND" {
                let command         = components[0]
                let pid             = components[1]
                let user            = components[2]
                let fileDescriptor  = components[3]
                let type            = components[4]
                let device          = components[5]
                let sizeOffset      = components[6]
                let node            = components[7]
                let nameParts       = components[8].components(separatedBy: "->")
                var name            = ""
                if nameParts.count == 2 {
                    let ipAddress   = nameParts[1].components(separatedBy: ":").first ?? ""
                    name            = ipAddress
                } else {
                    name = components[8]
                }
                
                if !(connections.contains(where: {
                    $0.name == name
                 })) {
                    let connection = Connection(
                        command: command,
                        pid: pid,
                        user: user,
                        fileDescriptor: fileDescriptor,
                        type: type,
                        device: device,
                        sizeOffset: sizeOffset,
                        node: node,
                        name: name
                    )
                    connections.append(connection)
                }
                
            }

        }
    }

    func getConnections() {
        for pid in pids {
            if let output = Command.runCommand("sudo lsof -i -a -p \(pid) -n") {
                parseOutput(output)
            }
        }
    }
}

extension TrafficMonitor: NSTableViewDelegate, NSTableViewDataSource {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnNumber = tableView.tableColumns.firstIndex(of: tableColumn!) else {
            return nil
        }
        
        // Force rewrite of the table. Don't care about cache.
        let textField = NSTextField()
        textField.identifier = NSUserInterfaceItemIdentifier("TextCell")
        textField.isEditable = false
        textField.bezelStyle = .roundedBezel
        textField.isBezeled = false
        textField.alignment = .center
        textField.font = NSFont(name: FONT, size: TABLE_FONT)
         
        if columnNumber == COLUMNS["PID"] {
            textField.stringValue = connections[row].pid
        } else if columnNumber == COLUMNS["IP"] {
            textField.isEditable = true
            textField.stringValue = connections[row].name
        }
        return textField
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return connections.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return HEIGHT
    }
}
