// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation
import os

// The per-device encryption key
fileprivate let DEVICE_KEY = "DEVICE_KEY_0"

/**
 Controls all aspects of encryption and decryption.

 This class is intended to be a singleton which is injected where needed.
 */
class CryptController {
    private let _log = OSLog()
    private let _key: Data

    init() {
        var key = getDeviceKey()
        key.append(contentsOf: [
            0xC8,
            0xAE,
            0x79,
            0x30,
            0xEC,
            0x8C,
            0xA1,
            0x7E,
            0xCC,
            0xDD,
            0xE2,
            0xED,
            0x1E,
            0xDF,
            0x36,
            0xF6,
        ])
        _key = key

        #if !CONFIGURATION_RELEASE
            os_log("Using key of %@", log: _log, type: .debug, key.base64EncodedString())
        #endif
    }

    // Reads the file from srcURL, encrypts it into dstURL then deletes srcURL
    func encryptThenDestroySourceFile(srcURL: URL, dstURL: URL) throws -> Int {
        let clearSize = try CryptController.encrypt(from: srcURL, to: dstURL, key: _key).clearSize
        let fileManager = FileManager()
        try fileManager.removeItem(at: srcURL)
        return clearSize
    }

    // Decrypts the file to a temporary self-destructing file
    func decryptToSelfDestructingFile(srcURL: URL) throws -> SelfDestructingFile {
        let dstURL = srcURL.appendingPathExtension(UUID().uuidString)
        _ = try CryptController.decrypt(from: srcURL, to: dstURL, key: _key)
        return SelfDestructingFile(fileURL: dstURL)
    }

    private struct Statistics {
        let clearSize: Int
        let cryptSize: Int
    }

    private enum DecryptError: Error {
        case invalidFile
    }

    private static func encrypt(from clearFileURL: URL, to cryptFileURL: URL, key: Data) throws -> Statistics {
        let clearFileReader = try FileReader(fileURL: clearFileURL)
        let cryptFileWriter = try FileWriter(fileURL: cryptFileURL)

        let iv = try CryptorIO.createRandomIV()
        let cryptorIO = try CryptorIO(encryptWithKey: key, iv: iv)
        try cryptFileWriter.write(data: iv)

        let (clearSize, cryptSize) = try process(cryptorIO: cryptorIO, chunkSize: 1_048_576, srcFileReader: clearFileReader, dstFileWriter: cryptFileWriter)

        return Statistics(clearSize: clearSize, cryptSize: cryptSize + iv.count)
    }

    private static func decrypt(from cryptFileURL: URL, to clearFileURL: URL, key: Data) throws -> Statistics {
        let cryptFileReader = try FileReader(fileURL: cryptFileURL)
        let clearFileWriter = try FileWriter(fileURL: clearFileURL)

        guard let iv = try cryptFileReader.read(count: CryptorIO.ivSize) else { throw DecryptError.invalidFile }
        let cryptorIO = try CryptorIO(decryptWithKey: key, iv: iv)

        let (cryptSize, clearSize) = try process(cryptorIO: cryptorIO, chunkSize: 1_048_576, srcFileReader: cryptFileReader, dstFileWriter: clearFileWriter)

        return Statistics(clearSize: clearSize, cryptSize: cryptSize + iv.count)
    }

    private static func process(cryptorIO: CryptorIO, chunkSize: Int, srcFileReader: FileReader, dstFileWriter: FileWriter) throws -> (Int, Int) {
        var srcSize = 0
        var dstSize = 0
        var srcChunk = Data(count: chunkSize)
        var dstChunk = Data(count: chunkSize + kCCBlockSizeAES128)
        try srcChunk.withUnsafeMutableBytes { unpopulatedSrcBuffer -> Void in
            try dstChunk.withUnsafeMutableBytes { unpopulatedDstBuffer -> Void in
                while true {
                    if let populatedSrcBuffer = try srcFileReader.read(into: unpopulatedSrcBuffer) {
                        let populatedDstBuffer = try cryptorIO.update(srcBuffer: populatedSrcBuffer, dstBuffer: unpopulatedDstBuffer)
                        try dstFileWriter.write(buffer: populatedDstBuffer)
                        srcSize += populatedSrcBuffer.count
                        dstSize += populatedDstBuffer.count
                    } else {
                        let populatedDstBuffer = try cryptorIO.final(dstBuffer: unpopulatedDstBuffer)
                        try dstFileWriter.write(buffer: populatedDstBuffer)
                        dstSize += populatedDstBuffer.count
                        break
                    }
                }
            }
        }
        return (srcSize, dstSize)
    }

    class SelfDestructingFile {
        private static let _log = OSLog()
        let fileURL: URL
        init(fileURL: URL) {
            self.fileURL = fileURL
        }

        deinit {
            SelfDestructingFile.deleteFile(fileURL: fileURL, previousAttempts: 0)
        }

        private static func deleteFile(fileURL: URL, previousAttempts: Int) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                os_log("Deleted file at %@", log: _log, type: .debug, String(describing: fileURL))
            } catch {
                let attempts = previousAttempts + 1
                if attempts > 20 {
                    os_log("Failed to delete file at %@", log: _log, type: .error, String(describing: fileURL))
                } else {
                    os_log("Error deleting file at %@, will retry", log: _log, type: .debug, String(describing: fileURL))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
                        deleteFile(fileURL: fileURL, previousAttempts: attempts)
                    }
                }
            }
        }
    }
}

fileprivate func getDeviceKey() -> Data {
    if let existingKey = getFromKeychain(key: DEVICE_KEY) {
        return existingKey
    }
    let keyLength = 16
    var key = Data(count: keyLength)
    let status = key.withUnsafeMutableBytes { keyPtr in
        SecRandomCopyBytes(kSecRandomDefault, keyLength, keyPtr)
    }
    guard status == 0 else { fatalError() }
    setInKeychain(key: DEVICE_KEY, value: key)
    return key
}

fileprivate func setInKeychain(key: String, value: Data) {
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: key,
                                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                kSecValueData as String: value]
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
        fatalError()
    }
}

fileprivate func getFromKeychain(key: String) -> Data? {
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: key,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess else { return nil }

    guard let existingItem = item as? [String: Any],
        let data = existingItem[kSecValueData as String] as? Data
    else {
        return nil
    }

    return data
}
