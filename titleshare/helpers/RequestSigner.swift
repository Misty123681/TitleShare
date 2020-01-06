// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

class RequestSigner {
    
    private static let _key = Data([0xB0, 0xFB, 0x1D, 0x3A, 0x3E, 0x87, 0xD6, 0xCB, 0x12, 0x26, 0x11, 0xC2, 0x29, 0x75, 0x72, 0xC6, 0x06, 0xAC, 0x0E, 0x9A, 0x3A, 0xB2, 0x3D, 0x89, 0x3F, 0x65, 0x09, 0xC1, 0xA7, 0xFA, 0x43, 0xC9, 0x59, 0x3B, 0xFE, 0xD1, 0xB2, 0x1E, 0x22, 0xAF, 0xB3, 0x0B ])
    
    // The order of the headers is important
    private static let _signedHeaders = ["User-Agent", "Authorization"]
    
    /**
     Creates a HMAC using the concatenated bytes (using UTF8 for strings) of the following fields
         - timestamp
         - HTTP method
         - URL path
         - Header values for each of _signedHeaders (in order)
         - The body bytes
     
     The HMAC is then base64 encoded and returned in the format 'v1 {timestamp} {signature}', suitable for the 'X-Signature' HTTP header
     This is the exact implementation matched on the server.
     */
    static func getRequestSignatureV1(forUrl: URL, method: String, headers: [String: String], body: Data) -> String {
        
        let timestamp = Date().millisecondsSince1970
        
        var fields = [String(timestamp), method, forUrl.path]
        
        for header in _signedHeaders {
            if let headerValue = headers[header] {
                fields.append(headerValue)
            }
        }
        
        let data = Data(fields.joined().utf8 + body)
        let hash = self._hmac(data: data, key: self._key)
        return "v1 \(timestamp) \(hash)"
    }
    
    private static func _hmac(data: Data, key: Data) -> String {
        let algorithm = CCHmacAlgorithm(kCCHmacAlgSHA256)
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        
        let hashBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: digestLength)
        defer { hashBytes.deallocate() }
        data.withUnsafeBytes { dataBuffer in
            key.withUnsafeBytes { keyBuffer in
                CCHmac(algorithm, keyBuffer.baseAddress, keyBuffer.count, dataBuffer.baseAddress, dataBuffer.count, hashBytes)
            }
        }
        
        let hmacData = Data(bytes: hashBytes, count: digestLength)
        return hmacData.base64EncodedString()
    }
}

