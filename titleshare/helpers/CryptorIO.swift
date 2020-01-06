// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

// See `man CCCryptor -s3`
class CryptorIO {
    enum Error: Swift.Error {
        case invalidKeySize
        case invalidIVSize
        case cryptorFailure
        case securityRandomFailure
    }

    convenience init(encryptWithKey key: Data, iv: Data) throws {
        try self.init(key: key, iv: iv, operation: CCOperation(kCCEncrypt))
    }

    convenience init(decryptWithKey key: Data, iv: Data) throws {
        try self.init(key: key, iv: iv, operation: CCOperation(kCCDecrypt))
    }

    private let _cryptorRef: CCCryptorRef

    private init(key: Data, iv: Data, operation: CCOperation) throws {
        guard [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256].contains(key.count) else { throw Error.invalidKeySize }
        guard iv.count == CryptorIO.ivSize else { throw Error.invalidIVSize }
        var maybeCryptorRef: CCCryptorRef?
        try key.withUnsafeBytes { keyBuffer in
            try iv.withUnsafeBytes { ivBuffer in
                guard CCCryptorCreate(
                    operation,
                    CCAlgorithm(kCCAlgorithmAES128),
                    CCOptions(kCCOptionPKCS7Padding),
                    keyBuffer.baseAddress, keyBuffer.count,
                    ivBuffer.baseAddress,
                    &maybeCryptorRef
                ) == kCCSuccess else { throw Error.cryptorFailure }
            }
        }
        guard let cryptorRef = maybeCryptorRef else { throw Error.cryptorFailure }
        _cryptorRef = cryptorRef
    }

    deinit {
        CCCryptorRelease(_cryptorRef)
    }

    static let ivSize = kCCBlockSizeAES128

    static func createRandomIV() throws -> Data {
        var iv = Data(count: ivSize)
        try iv.withUnsafeMutableBytes { ivBuffer in
            guard Security.SecRandomCopyBytes(kSecRandomDefault, ivBuffer.count, ivBuffer.baseAddress!) == Security.errSecSuccess else { throw Error.securityRandomFailure }
        }
        return iv
    }

    func update(srcBuffer: UnsafeRawBufferPointer, dstBuffer: UnsafeMutableRawBufferPointer) throws -> UnsafeRawBufferPointer {
        var movedSize = 0
        guard CCCryptorUpdate(
            _cryptorRef,
            srcBuffer.baseAddress, srcBuffer.count,
            dstBuffer.baseAddress, dstBuffer.count,
            &movedSize
        ) == kCCSuccess else { throw Error.cryptorFailure }
        return UnsafeRawBufferPointer(rebasing: dstBuffer[0 ..< movedSize])
    }

    func final(dstBuffer: UnsafeMutableRawBufferPointer) throws -> UnsafeRawBufferPointer {
        var movedSize = 0
        guard CCCryptorFinal(
            _cryptorRef,
            dstBuffer.baseAddress, dstBuffer.count,
            &movedSize
        ) == kCCSuccess else { throw Error.cryptorFailure }
        return UnsafeRawBufferPointer(rebasing: dstBuffer[0 ..< movedSize])
    }
}
