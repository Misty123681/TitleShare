// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation
import os

class ApplicationFileURLs {
    private let _log = OSLog()
    private let _applicationSupportBundleDirectory: URL

    let modelFileURL: URL
    let fileResourceDirectoryURL: URL

    init() {
        let fileManager = FileManager()
        let applicationSupportDirectory = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var applicationSupportBundleDirectory = applicationSupportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
        // Cache_0 was 2.0.1 (21) and below (never publicly released)
        // Cache_1 introduced to support encryption at rest for audio files
        let cacheDirectory = applicationSupportBundleDirectory.appendingPathComponent("Cache_1", isDirectory: true)
        try! fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try! applicationSupportBundleDirectory.setResourceValues(resourceValues)
        modelFileURL = cacheDirectory.appendingPathComponent("Model", isDirectory: false)
        fileResourceDirectoryURL = cacheDirectory.appendingPathComponent("FileResources", isDirectory: true)
        try! fileManager.createDirectory(at: fileResourceDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        _applicationSupportBundleDirectory = applicationSupportBundleDirectory
    }

    func cleanFileResourceDirectory(fileResourcesToKeep: [FileResource]) {
        let keepFilePaths = Set(fileResourcesToKeep.compactMap {
            $0.state.value.fileURL?.absoluteString
        })
        let fileManager = FileManager()
        guard let contents = try? fileManager.contentsOfDirectory(at: fileResourceDirectoryURL, includingPropertiesForKeys: [.isRegularFileKey], options: []) else {
            os_log("Failed to enumerate files (for deletion) in %@", log: _log, type: .error, String(describing: fileResourceDirectoryURL))
            return
        }
        for var foundURL in contents {
            foundURL.resolveSymlinksInPath()
            foundURL.standardize()
            if !keepFilePaths.contains(foundURL.absoluteString) {
                do {
                    try fileManager.removeItem(at: foundURL)
                    os_log("Deleted file %@", log: self._log, type: .info, String(describing: foundURL))
                } catch {
                    os_log("Failed to delete file %@", log: self._log, type: .error, String(describing: foundURL))
                }
            }
        }
    }

    func cleanSupersededCaches() {
        cleanPreV_2()
        cleanPreV_2_2()
    }

    private func cleanPreV_2() {
        let fileManager = FileManager()
        let sandboxDirectory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        let libraryDirectory = sandboxDirectory.appendingPathComponent("Library")
        let cacheDirectory = libraryDirectory.appendingPathComponent("Audiobookscache")
        try? fileManager.removeItem(at: cacheDirectory)
    }

    private func cleanPreV_2_2() {
        let fileManager = FileManager()
        let cache0Directory = _applicationSupportBundleDirectory.appendingPathComponent("Cache_0", isDirectory: true)
        try? fileManager.removeItem(at: cache0Directory)
    }
}
