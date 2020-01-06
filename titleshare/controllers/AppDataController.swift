// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation
import os

struct Credentials {
    var username: String
    var password: String
}

class AppDataController {
    private let SERVER = "title-share.net"
    private let USER_AUTH_TOKEN_KEY = "USER_AUTH_TOKEN_KEY"
    private let _log = OSLog()
    private var lock = os_unfair_lock()
    private var _userAuthToken: String?

    // accessed from FileResource code, thus needs to be thread-safe
    var userAuthToken: String? {
        get {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return _userAuthToken
        }
        set(value) {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            _userAuthToken = value
            if let token = value {
                setKeyChainValue(for: USER_AUTH_TOKEN_KEY, value: token)
            } else {
                removeKeyChainValue(for: USER_AUTH_TOKEN_KEY)
            }
        }
    }

    init() {
        _userAuthToken = getKeyChainValue(key: USER_AUTH_TOKEN_KEY)
    }

    /** Stores a users titleshare credentials in the keychain  */
    public func setUserCredentials(credentials: Credentials) {
        let existingCreds = getUserCredentials()

        if let existingCreds = existingCreds {
            if existingCreds.username != credentials.username || existingCreds.password != credentials.password {
                // Update the credentials in the keychain
                let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                            kSecAttrServer as String: SERVER]
                let attributes: [String: Any] = [kSecAttrAccount as String: credentials.username,
                                                 kSecValueData as String: credentials.password.data(using: String.Encoding.utf8)!]
                let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
                guard status == errSecSuccess else {
                    os_log("Could not update credentials in keychain: %@", log: _log, type: .error, String(describing: status))
                    return
                }
            }
        } else {
            let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                        kSecAttrAccount as String: credentials.username,
                                        kSecAttrServer as String: SERVER,
                                        kSecValueData as String: credentials.password.data(using: String.Encoding.utf8)!]

            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else {
                os_log("Could not add credentials to keychain: %@", log: _log, type: .error, String(describing: status))
                return
            }
        }
    }

    /** Retrives a users titleshare credentials from the keychain  */
    public func getUserCredentials() -> Credentials? {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: SERVER,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            os_log("Credentials not found in keychain: %@", log: _log, type: .default, String(describing: status))
            return nil
        }

        guard let existingItem = item as? [String: Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8),
            let account = existingItem[kSecAttrAccount as String] as? String
        else {
            return nil
        }

        return Credentials(username: account, password: password)
    }

    public func removeUserCredentials() {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: SERVER]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            os_log("Error deleting credentials from keychain: %@", log: _log, type: .error, String(describing: status))
            return
        }
    }

    // MARK: Private functions

    private func setKeyChainValue(for key: String, value: String) {
        let data = value.data(using: String.Encoding.utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: key,
                                    kSecValueData as String: data]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            os_log("Could not add item %@ to keychain: %@", log: _log, type: .error, key, String(describing: status))
            return
        }
    }

    private func getKeyChainValue(key: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: key,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            os_log("Item %@ not found in keychain: %@", log: _log, type: .default, key, String(describing: status))
            return nil
        }

        guard let existingItem = item as? [String: Any],
            let data = existingItem[kSecValueData as String] as? Data,
            let dataString = String(data: data, encoding: String.Encoding.utf8)
        else {
            return nil
        }

        return dataString
    }

    private func removeKeyChainValue(for key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: key]
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            os_log("Error deleting item %@ from keychain: %@", log: _log, type: .error, key, String(describing: status))
            return
        }
    }
}
