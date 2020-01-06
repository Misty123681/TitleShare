// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Alamofire
import Foundation

struct Constants {
    #if CONFIGURATION_DEBUG
        private static let _serverEndpoint = "https://demo.title-share.net"
    #elseif CONFIGURATION_ADHOC
        private static let _serverEndpoint = "https://demo.title-share.net"
    #elseif CONFIGURATION_RELEASE
        private static let _serverEndpoint = "https://portal.title-share.net"
    #else
        #error("unknown configuration")
    #endif

    static let websiteUrl = "\(_serverEndpoint)"
    static let graphqlEndpoint = "\(_serverEndpoint)/graphql"
    static let termsAndConditionsUrl = "\(_serverEndpoint)/terms"
    static let privacyUrl = "\(_serverEndpoint)/privacy"
    static let faqUrl = "https://www.booktrack.com/titleshare-faq"
    static let supportEmail = "support@booktrack.com"

    #if CONFIGURATION_DEBUG
        // We intentionally do not enable anything app center related for debug builds
    #elseif CONFIGURATION_ADHOC
        static let appCenterAppSecret = "c5c4b879-324a-4759-802f-cbbd8a8430ee"
    #elseif CONFIGURATION_RELEASE
        static let appCenterAppSecret = "a632a0e9-a23a-4f7c-8376-86da435afd00"
    #else
        #error("unknown configuration")
    #endif

    static let userAgent: String = {
        let appNameVersion: String = {
            let info = Bundle.main.infoDictionary
            let name = info?[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
            let version = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
            return "\(name)/\(version)"
        }()

        let osNameVersion: String = {
            let name: String = {
                #if os(iOS)
                    return "iOS"
                #elseif os(watchOS)
                    return "watchOS"
                #elseif os(tvOS)
                    return "tvOS"
                #elseif os(macOS)
                    return "macOS"
                #elseif os(Linux)
                    return "Linux"
                #else
                    return "Unknown"
                #endif
            }()
            let version: String = {
                let version = ProcessInfo.processInfo.operatingSystemVersion
                return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
            }()
            return "\(name)/\(version)"
        }()

        let hardwareModel: String = {
            var name: [Int32] = [CTL_HW, HW_MACHINE]
            var bufferLength: Int = 0
            sysctl(&name, UInt32(name.count), nil, &bufferLength, nil, 0)
            // The man page for sysctl is pretty unclear about whether the copied string
            // includes the null termination or not, add 1 for safety just in case
            var buffer = [CChar](repeating: 0, count: bufferLength + 1)
            sysctl(&name, UInt32(name.count), &buffer, &bufferLength, nil, 0)

            // The man page for sysctl is pretty unclear about whether the char[] is
            // utf8 or ascii...
            // We don't expect it be non-ascii, and the cString initializer will
            // replace invalid sequences, so it seems safe enough
            let machine: String = String(cString: buffer)
            // We might be running on a simulator
            if machine == "x86_64" || machine == "i386" {
                let simulatorModelIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "unknown"
                return "\(simulatorModelIdentifier)/\(machine)_simulator"
            }
            return machine
        }()

        let alamofireNameVersion: String = {
            guard
                let info = Bundle(for: SessionManager.self).infoDictionary,
                let version = info["CFBundleShortVersionString"]
            else { return "Unknown" }

            return "Alamofire/\(version)"
        }()

        return "\(appNameVersion) (\(osNameVersion); \(hardwareModel)) \(alamofireNameVersion)"
    }()

    #if CONFIGURATION_DEBUG
        static let httpLoggingEnabled = true
    #else
        static let httpLoggingEnabled = false
    #endif
}
