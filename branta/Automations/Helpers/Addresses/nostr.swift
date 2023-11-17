import Foundation

//https://github.com/nostr-protocol/nips/blob/master/19.md

class NostrAddress {
    
    
    // npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6
    static func isValidNPUB(str: String) -> Bool {
        let npubAddressRegex = try! NSRegularExpression(pattern: "^npub[0-9a-z]{58,65}$", options: .caseInsensitive)
        let range = NSRange(location: 0, length: str.utf16.count)
        let match = npubAddressRegex.firstMatch(in: str, options: [], range: range) != nil
        
        return match
    }
    
    
    //nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5
    static func isValidNSEC(str: String) -> Bool {
        let npubAddressRegex = try! NSRegularExpression(pattern: "^nsec[0-9a-z]{58,65}$", options: .caseInsensitive)
        let range = NSRange(location: 0, length: str.utf16.count)
        let match = npubAddressRegex.firstMatch(in: str, options: [], range: range) != nil
        
        return match
    }

}
