//
//  HMAC.swift
//
//  Created by Mihael Isaev on 21.04.15.
//  Copyright (c) 2014 Mihael Isaev inc. All rights reserved.
//
// ***********************************************************
//
// How to import CommonCrypto in Swift project without Obj-c briging header
//
// To work around this create a directory called CommonCrypto in the root of the project using Finder.
// In this directory create a file name module.map and copy the following into the file.
// You will need to alter the paths to ensure they point to the headers on your system.
//
// module CommonCrypto [system] {
//     header "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/CommonCrypto/CommonCrypto.h"
//     export *
// }
// To make this module visible to Xcode, go to Build Settings, Swift Compiler – Search Paths
// and set Import Paths to point to the directory that contains the CommonCrypto directory.
//
// You should now be able to use import CommonCrypto in your Swift code.
//
// You have to set the Import Paths in every project that uses your framework so that Xcode can find it.
//
// ***********************************************************
//

import Foundation
import CommonCrypto

enum HMACAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    func toCCHmacAlgorithm() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .SHA224:
            result = kCCHmacAlgSHA224
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    func hmac(algorithm: HMACAlgorithm, key: String) -> String {
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = self.cString(using: String.Encoding.utf8)
        var result = [CUnsignedChar](repeating: 0, count: Int(algorithm.digestLength()))
        CCHmac(algorithm.toCCHmacAlgorithm(), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData:NSData = NSData(bytes: result, length: (Int(algorithm.digestLength())))
        let hmacBase64 = hmacData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)

        return String(hmacBase64)
    }
    
    func hmacHexa(algorithm: HMACAlgorithm, key: String) -> String {
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = self.cString(using: String.Encoding.utf8)
        var result = [CUnsignedChar](repeating: 0, count: Int(algorithm.digestLength()))
        let length : Int = Int(strlen(cKey!))
        let data : Int = Int(strlen(cData!))
        CCHmac(algorithm.toCCHmacAlgorithm(), cKey!,length , cData!, data, &result)
        
        let hmacData:NSData = NSData(bytes: result, length: (Int(algorithm.digestLength())))
        
        var bytes = [UInt8](repeating: 0, count: hmacData.length)
        hmacData.getBytes(&bytes, length: hmacData.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02hhx", UInt8(byte))
        }
        return hexString
    }
}
