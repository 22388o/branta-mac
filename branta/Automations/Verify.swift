//
//  Verify.swift
//  branta
//
//  Created by Keith Gardner on 11/20/23.
//

import Cocoa
import CryptoKit
import Foundation


let SPARROW              = "Sparrow.app"
let TREZOR               = "Trezor Suite.app"
let LEDGER               = "Ledger Live.app"
let BLOCKSTREAM_GREEN    = "Blockstream Green.app"

class Verify: Automation {
    static var notificationManager: NotificationManager?
    static var alreadyWarned = [
        SPARROW: false,
        LEDGER: false,
        TREZOR: false,
        BLOCKSTREAM_GREEN: false
    ]
    static let TARGETS : Set = [SPARROW, TREZOR, LEDGER, BLOCKSTREAM_GREEN]
    static let VERIFY_INTERVAL = 10.0
    static let PATH = "/Applications"
    static let FM = FileManager.default
    static let USE_SHORT_VERSION_PATH = [BLOCKSTREAM_GREEN]
    private static var observers = [VerifyObserver]()
    static var signatures: Array<[String: String]> = [] {
        didSet {
            notifyObservers()
        }
    }

    override class func run() {
        setup()
        
        Timer.scheduledTimer(withTimeInterval: VERIFY_INTERVAL, repeats: true) { _ in
            verify()
        }
    }
    
    static func verify() {
        setup()
        let wallets = crawlWallets()
        signatures = matchSignatures(wallets: wallets)
    }
    
    static func addObserver(_ observer: VerifyObserver) {
        observers.append(observer)
    }

    static func removeObserver(_ observer: VerifyObserver) {
        observers.removeAll { $0 === observer }
    }
    
    static func notifyObservers() {
        for observer in observers {
            observer.verifyDidChange(newResults: signatures)
        }
    }
    
    private
    
    static func setup() {
        if notificationManager == nil {   
            notificationManager = NotificationManager()
            notificationManager?.requestAuthorization()
        }
    }
    
    static func matchSignatures(wallets: Array<[String: String]>) -> Array<[String: String]> {
        let architectureSpecificHashes = HashGrabber.grab()
        var ret: Array<[String: String]> = []
        
        // TODO - Early exit
        for wallet in wallets {
            if let name = wallet["name"] {
                for hash in architectureSpecificHashes {
                    if hash[name] != nil {
                        if let walletVersionPair = hash[name] {
                            var retItem = wallet
                            for kv in walletVersionPair {
                                if kv.value == wallet["hash"] {
                                    retItem["match"] = "true"
                                }
                            }
                            ret.append(retItem)
                        }
                    }
                }
            }
        }
                
        // Second pass
        // Notify if:
        // A wallet has false and has not already sent user alert
        // Branta is in background (don't notify in foreground, nothing happens)
        for wallet in ret {
            if let match = wallet["match"] {
                if match == "false" {
                    let app = wallet["name"]!
                    let name = stripAppSuffix(str: app)
                    
                    // Rudimentary.... we only alert user once per app start up that their wallet is not verified.
                    // We can let the user decide how noisy Branta is.
                    let appDelegate = NSApp.delegate as? AppDelegate
                    if alreadyWarned[app] == false && !appDelegate!.foreground {
                        notificationManager?.showNotification(title: "Could not verify \(name)", body: "")
                        alreadyWarned[app] = true
                    }
                }
            }
        }
        
        return ret
    }
    
    static func stripAppSuffix(str: String) -> String {
        return str.replacingOccurrences(of: ".app", with: "")
    }
    
    static func crawlWallets() -> Array<[String: String]> {
        var ret : Array<[String: String]> = []

        do {
            let items = try FM.contentsOfDirectory(atPath: PATH)

            for item in items {
                if TARGETS.contains(item) {
                    let fullPath = PATH + "/" + item + "/Contents/MacOS/" + item.dropLast(4)
                    let hash = sha256(at: fullPath)
                    let version = getAppVersion(atPath: (PATH + "/" + item))
                    
                    ret.append([
                        "name": item,
                        "path": fullPath,
                        "hash": hash,
                        "match": "false",
                        "version": version
                    ])
                }
            }
            return ret
        } catch {
            print("Verify Automation: Caught an error in crawlWallets()")
        }
        return []
    }
        
    static func getAppVersion(atPath appPath: String) -> String {
        let infoPlistPath = appPath + "/Contents/Info.plist"
        var key = "CFBundleShortVersionString"
        
        // A few wallets (Blockstream Green) use CFBundleVersion. Display that to user.
        for item in USE_SHORT_VERSION_PATH {
            if appPath.contains(item) {
                key = "CFBundleVersion"
            }
        }
        
        guard let infoDict = NSDictionary(contentsOfFile: infoPlistPath),
              let version = infoDict[key] as? String else {
            return "nil"
        }
        
        return version
    }
    
    static func sha256(at filePath: String) -> String {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let hashed = SHA256.hash(data: data)
            return hashed.compactMap { String(format: "%02x", $0) }.joined()
        } catch {
            // TODO - need handling
            print("sha256() Error reading file: \(error)")
            return ""
        }
    }
}
