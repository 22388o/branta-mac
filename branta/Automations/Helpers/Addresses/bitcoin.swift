import Foundation


//https://github.com/vtm9/adequate_crypto_address
//https://stackoverflow.com/questions/22127317/check-if-bitcoin-address-is-valid


class BitcoinAddress {
    static func isValid(str: String) -> Bool {
        // Check pre-segWit
        let bitcoinAddressRegex = try! NSRegularExpression(pattern: "^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$", options: .caseInsensitive)
        var range = NSRange(location: 0, length: str.utf16.count)
        let preSegWit = bitcoinAddressRegex.firstMatch(in: str, options: [], range: range) != nil
        
        // Check segWit
        let segWitAddressRegex = try! NSRegularExpression(pattern: "^bc1[0-9a-zA-Z]{25,39}$", options: .caseInsensitive)
        range = NSRange(location: 0, length: str.utf16.count)
        let segWit = segWitAddressRegex.firstMatch(in: str, options: [], range: range) != nil
        
        return preSegWit || segWit
    }
    
    // Checks whether a given string is formatted as a valid mainnet bitcoin extended public key.
    // See https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki
    // See https://github.com/unchained-capital/unchained-bitcoin/blob/db5b56cc217f2306b1d7e09efc77a00301593870/src/networks.ts#L47-L65
    static func isValidXPUB(str: String) -> Bool {
        
        let isXPUB = str.starts(with: "xpub") || //Legacy
        str.starts(with: "ypub") || //SegWit
        str.starts(with: "zpub") // Bech32 (Native Segwit)
        
        
        return isXPUB && str.count > 10
    }
    
    static func isValidXPRV(str: String) -> Bool {
        return str.starts(with: "xprv") && str.count > 10
    }
}
