//
//  KeychainController.swift
//  OandaChandler
//
//  Created by Paweł Karaś on 31/12/2022.
//

import Foundation
import Security

let keychainService = Bundle.main.bundleIdentifier // replace with your app's unique identifier

// Store data in the keychain
func storeDataInKeychain(_ key: String, data: String) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: keychainService!,
        kSecAttrAccount as String: key,
        kSecValueData as String: data.data(using: .utf8)!
    ]
    Task {
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            let attributes: [String: Any] = [
                kSecAttrAccount as String: key,
                kSecValueData as String: data.data(using: .utf8)!
            ]
            let result = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if result != errSecSuccess {
                print("Error storing data in keychain: \(status)")
            }
        }
    }
}

// Retrieve data from the keychain
func getDataFromKeychain(_ key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: keychainService!,
        kSecAttrAccount as String: key,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecSuccess {
        if let res = result as? Data {
            return String(decoding: res, as: UTF8.self)
        } else {
            return nil
        }
    } else if status == errSecItemNotFound {
        return nil
    } else {
        print("Error retrieving data from keychain: \(status)")
        return nil
    }
}
