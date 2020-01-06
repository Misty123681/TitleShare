// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation
import os

/**
 A FileResource represents a file that is downloading or downloaded.
 */
public class FileResource {
    // MARK: public FileResource

    public typealias Id = URL

    public enum State {
        case pending(downloadedSizeInBytes: Int64)
        case available(fileURL: URL, sizeInBytes: Int64)

        var available: Bool {
            switch self {
            case .pending:
                return false
            case .available:
                return true
            }
        }

        var finalOrDownloadedSizeInBytes: Int64 {
            switch self {
            case let .pending(downloadedSizeInBytes):
                return downloadedSizeInBytes
            case let .available(_, sizeInBytes):
                return sizeInBytes
            }
        }

        var fileURL: URL? {
            switch self {
            case .pending:
                return nil
            case let .available(fileURL, _):
                return fileURL
            }
        }
    }

    public let remoteURL: Id
    public let encrypted: Bool
    public var state: Watchable<State> {
        return _state.watchable
    }

    // MARK: internal FileResource

    enum InternalState: Codable {
        case idle(Idle)
        case downloading(Downloading)
        case downloaded(Downloaded)

        struct Idle: Codable {
            let resumable: Resumable?
            var lastClientHTTPError: Int? = nil

            struct Resumable: Codable {
                let resumeData: Data
                let downloadedSizeInBytes: Int64
            }

            private enum CodingKeys: String, CodingKey {
                case resumable
                // We don't care about persisting the last error
                // case lastClientHTTPError
            }
        }

        struct Downloading: Codable {
            var task: URLSessionDownloadTask? = nil
            let downloadedSizeInBytes: Int64

            private enum CodingKeys: String, CodingKey {
                case downloadedSizeInBytes
            }
        }

        struct Downloaded: Codable {
            let filename: String
            let sizeInBytes: Int64
        }

        private enum CodingKeys: String, CodingKey {
            case idle
            case downloading
            case downloaded
        }

        private enum CodingError: Error {
            case decoding(String)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guard let key = container.allKeys.first else { throw CodingError.decoding("No valid keys in: \(container)") }
            func decode<T: Decodable>() throws -> T { return try container.decode(T.self, forKey: key) }
            switch key {
            case .idle:
                self = .idle(try decode())
            case .downloading:
                self = .downloading(try decode())
            case .downloaded:
                self = .downloaded(try decode())
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .idle(associatedValue):
                try container.encode(associatedValue, forKey: .idle)
            case let .downloading(associatedValue):
                try container.encode(associatedValue, forKey: .downloading)
            case let .downloaded(associatedValue):
                try container.encode(associatedValue, forKey: .downloaded)
            }
        }

        var finalOrDownloadedSizeInBytes: Int64 {
            switch self {
            case let .idle(idle):
                return idle.resumable?.downloadedSizeInBytes ?? 0
            case let .downloading(downloading):
                return downloading.downloadedSizeInBytes
            case let .downloaded(downloaded):
                return downloaded.sizeInBytes
            }
        }
    }

    struct Memento: Codable {
        let remoteURL: URL
        let encrypted: Bool
        let state: InternalState
    }

    var memento: Memento {
        return Memento(remoteURL: remoteURL, encrypted: encrypted, state: internalState)
    }

    // MARK: fileprivate FileResource

    fileprivate var internalState: InternalState {
        get {
            assert(fileResourceController.orderlyQueue.onDispatchQueue)
            return _internalState
        }
        set(value) {
            assert(fileResourceController.orderlyQueue.onDispatchQueue)
            _internalState = value
            DispatchQueue.main.async {
                self._state.value = FileResource.stateFrom(internalState: value, fileResourceController: self.fileResourceController)
            }
        }
    }

    fileprivate init(from memento: Memento, fileResourceController: FileResourceController) {
        remoteURL = memento.remoteURL
        encrypted = memento.encrypted
        self.fileResourceController = fileResourceController
        _internalState = memento.state
        _state = Watchable.Source(value: FileResource.stateFrom(internalState: _internalState, fileResourceController: fileResourceController))
    }

    fileprivate init(remoteURL: URL, encrypted: Bool, fileResourceController: FileResourceController) {
        self.remoteURL = remoteURL
        self.encrypted = encrypted
        self.fileResourceController = fileResourceController
        _internalState = .idle(InternalState.Idle(resumable: nil, lastClientHTTPError: nil))
        _state = Watchable.Source(value: FileResource.stateFrom(internalState: _internalState, fileResourceController: fileResourceController))
    }

    // MARK: private FileResource

    private let fileResourceController: FileResourceController
    private let _state: Watchable<State>.Source
    private var _internalState: InternalState

    deinit {
        fileResourceController.orderlyQueue.dispatchQueue.sync {
            fileResourceController.forget(fileResource: self)
            switch internalState {
            case let .downloading(downloading):
                if let task = downloading.task {
                    task.cancel()
                }
            default:
                ()
            }
        }
    }

    private static func stateFrom(internalState: InternalState, fileResourceController: FileResourceController) -> State {
        switch internalState {
        case .idle, .downloading:
            return .pending(downloadedSizeInBytes: internalState.finalOrDownloadedSizeInBytes)
        case let .downloaded(downloaded):
            var fileURL = fileResourceController.fileResourceDirectoryURL.appendingPathComponent(downloaded.filename, isDirectory: false)
            fileURL.resolveSymlinksInPath()
            fileURL.standardize()
            return .available(fileURL: fileURL, sizeInBytes: downloaded.sizeInBytes)
        }
    }
}

class FileResourceController {
    // MARK: public FileResourceController

    public func fileResource(remoteURL: URL, encrypted: Bool) -> FileResource {
        return orderlyQueue.dispatchQueue.sync {
            if let fileResource = fileResourcesById[remoteURL]?.fileResource {
                return fileResource
            }
            let fileResource = remember(fileResource: FileResource(remoteURL: remoteURL, encrypted: encrypted, fileResourceController: self))
            downloader?.transitionFromIdle(fileResource: fileResource)
            return fileResource
        }
    }

    public var handleEventsForBackgroundURLSessionCompletionHandler: (() -> Void)?

    public func createURLSessionOnce() {
        guard downloader == nil else { return }
        downloader = Downloader(fileResourceController: self)
    }

    public func synchroniseURLSessionOnce() {
        guard let downloader = downloader else { return }
        guard !synchronisedWithURLSession else { return }
        synchronisedWithURLSession = true
        orderlyQueue.dispatchQueue.async {
            downloader.synchroniseURLSession()
        }
    }

    // MARK: internal FileResourceController

    struct Memento: Codable {
        let fileResources: [FileResource.Memento]
    }

    var memento: Memento {
        return orderlyQueue.dispatchQueue.sync { Memento(fileResources: fileResourcesById.values.compactMap({ $0.fileResource?.memento })) }
    }

    init(from memento: Memento?, intoOwnedFileResources: inout [FileResource], authenticationController: AuthenticationController, fileResourceDirectoryURL: URL, cryptController: CryptController) {
        self.authenticationController = authenticationController
        self.fileResourceDirectoryURL = fileResourceDirectoryURL
        self.cryptController = cryptController
        if let memento = memento {
            intoOwnedFileResources = memento.fileResources.map({
                let fileResource = FileResource(from: $0, fileResourceController: self)
                _fileResourcesById[fileResource.remoteURL] = WeakFileResource(fileResource: fileResource)
                return fileResource
            })
        }
    }

    // MARK: fileprivate FileResourceController

    fileprivate struct WeakFileResource {
        weak var fileResource: FileResource?
    }

    fileprivate let authenticationController: AuthenticationController
    fileprivate let fileResourceDirectoryURL: URL
    fileprivate let cryptController: CryptController
    fileprivate var fileResourcesById: [FileResource.Id: WeakFileResource] {
        get {
            assert(orderlyQueue.onDispatchQueue)
            return _fileResourcesById
        }
        set(value) {
            assert(orderlyQueue.onDispatchQueue)
            _fileResourcesById = value
        }
    }

    /** All interactions with internal state of FileResourceController and FileResource, or the URLSession MUST be performed on the contained dispatch queue. */
    fileprivate let orderlyQueue: MarkedDispatchQueue = MarkedDispatchQueue(dispatchQueue: DispatchQueue(label: "com.booktrack.titleshare.FileResourceController"))

    fileprivate func forget(fileResource: FileResource) {
        assert(fileResourcesById[fileResource.remoteURL] != nil)
        fileResourcesById[fileResource.remoteURL] = nil
    }

    // MARK: private FileResourceController

    private var _fileResourcesById: [FileResource.Id: WeakFileResource] = [:]
    private var downloader: Downloader?
    private var synchronisedWithURLSession = false

    private func remember(fileResource: FileResource) -> FileResource {
        assert(fileResourcesById[fileResource.remoteURL] == nil)
        fileResourcesById[fileResource.remoteURL] = WeakFileResource(fileResource: fileResource)
        return fileResource
    }
}

/**
 Handles the messy details of interfacing with NSURLSession for downloading.

 This class is intentionally tightly coupled to the FileResourceController and FileResource classes.
 */
fileprivate class Downloader: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    // MARK: public Downloader

    // MARK: URLSessionDelegate

    func urlSessionDidFinishEvents(forBackgroundURLSession _: URLSession) {
        os_log("urlSessionDidFinishEvents", log: log, type: .info)
        assert(orderlyQueue.onDispatchQueue)
        guard let fileResourceController = fileResourceController else { return }
        if let eventsCompletionHandler = fileResourceController.handleEventsForBackgroundURLSessionCompletionHandler {
            fileResourceController.handleEventsForBackgroundURLSessionCompletionHandler = nil
            DispatchQueue.main.async {
                eventsCompletionHandler()
            }
        }
    }

    // MARK: URLSessionDownloadDelegate

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite _: Int64) {
        assert(orderlyQueue.onDispatchQueue)
        guard let remoteURL = downloadTask.originalRequest?.url else { return }
        os_log("didWriteData for %@", log: log, type: .debug, remoteURL.description)
        guard let fileResource = fileResourceController?.fileResourcesById[remoteURL]?.fileResource else { return }
        switch fileResource.internalState {
        case .idle, .downloading:
            ()
        default:
            return
        }
        fileResource.internalState = .downloading(FileResource.InternalState.Downloading(task: downloadTask, downloadedSizeInBytes: totalBytesWritten))
    }

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        assert(orderlyQueue.onDispatchQueue)
        guard let remoteURL = downloadTask.originalRequest?.url else { return }
        os_log("didFinishDownloadingTo for %@", log: log, type: .info, remoteURL.description)
        guard let fileResourceController = fileResourceController else { return }
        guard let fileResource = fileResourceController.fileResourcesById[remoteURL]?.fileResource else { return }
        switch fileResource.internalState {
        case .idle, .downloading:
            ()
        default:
            return
        }
        // Observed a bug in the wild whereby either the response was null or the response was not a HTTPURLResponse
        // No idea how that is possible, or what to do about it, but better off not crashing, I guess
        guard let response = downloadTask.response as? HTTPURLResponse else { return }
        os_log("didFinishDownloadingTo for %@ status %@", log: log, type: .debug, remoteURL.description, response.statusCode.description)
        if response.statusCode == .some(200) {
            let fileManager = FileManager()
            for _ in 1 ... 3 {
                let permanentFilename = UUID().uuidString
                let permanentURL = fileResourceController.fileResourceDirectoryURL.appendingPathComponent(permanentFilename, isDirectory: false)
                do {
                    let sizeInBytes: Int64
                    if fileResource.encrypted {
                        sizeInBytes = Int64(try cryptController.encryptThenDestroySourceFile(srcURL: location, dstURL: permanentURL))
                    } else {
                        try fileManager.moveItem(at: location, to: permanentURL)
                        // Irreproducible bug observed in the wild whereby the fileSize could not be retrieved from `location`, causing a crash.
                        // This code arrangement attempts to fix it by:
                        // 1) using `permanentURL` instead of `location`, thus measuring the post moved file (perhaps it was a file permission issue?)
                        // 2) avoiding assertions, and using sane defaults if the fileSize cannot be determined
                        // Worst case of an inaccurate `sizeInBytes` is funky progress indication, which is preferable to crashing.
                        if let fileSizeInBytes = (try? permanentURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                            sizeInBytes = Int64(fileSizeInBytes)
                        } else {
                            sizeInBytes = fileResource.internalState.finalOrDownloadedSizeInBytes
                        }
                    }
                    fileResource.internalState = .downloaded(FileResource.InternalState.Downloaded(filename: permanentFilename, sizeInBytes: sizeInBytes))
                    return
                } catch {
                    // loop again, if we haven't exhausted our retry attempts
                }
            }
            os_log("failed to move for %@", log: log, type: .error, remoteURL.description)
            try? fileManager.removeItem(at: location)
        }
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        assert(orderlyQueue.onDispatchQueue)
        guard let downloadTask = task as? URLSessionDownloadTask else { return }
        guard let remoteURL = downloadTask.originalRequest?.url else { return }
        os_log("didCompleteWithError for %@: %@", log: log, type: .info, remoteURL.description, error.debugDescription)
        guard let fileResource = fileResourceController?.fileResourcesById[remoteURL]?.fileResource else { return }
        switch fileResource.internalState {
        case .idle, .downloading:
            ()
        default:
            return
        }
        if let transportError = error {
            if let resumeData = (transportError as? URLError)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                let resumable = FileResource.InternalState.Idle.Resumable(resumeData: resumeData, downloadedSizeInBytes: fileResource.internalState.finalOrDownloadedSizeInBytes)
                fileResource.internalState = .idle(FileResource.InternalState.Idle(resumable: resumable, lastClientHTTPError: nil))
            } else {
                fileResource.internalState = .idle(FileResource.InternalState.Idle(resumable: nil, lastClientHTTPError: nil))
            }
        } else if let response = downloadTask.response as? HTTPURLResponse {
            switch response.statusCode {
            case 200:
                // do nothing, case dealt with in urlSessionDownloadTaskDidDownloadFile for reasons of atomicity
                // this is theoretically unreachable... (state will already be downloaded)
                ()
            case 400 ..< 500:
                fileResource.internalState = .idle(FileResource.InternalState.Idle(resumable: nil, lastClientHTTPError: response.statusCode))
            default:
                fileResource.internalState = .idle(FileResource.InternalState.Idle(resumable: nil, lastClientHTTPError: nil))
            }
        } else {
            // Something, somewhere, went terribly wrong
            fileResource.internalState = .idle(FileResource.InternalState.Idle(resumable: nil, lastClientHTTPError: nil))
        }
    }

    // MARK: fileprivate Downloader

    fileprivate init(fileResourceController: FileResourceController) {
        self.fileResourceController = fileResourceController
        cryptController = fileResourceController.cryptController
        orderlyQueue = fileResourceController.orderlyQueue
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.booktrack.titleshare.Downloader")
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = orderlyQueue.dispatchQueue
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
    }

    /**
     Perform a sanity check of what tasks the URLSession has versus what we think the URLSession should have.

     This shouldn't really be necessary... but, URLSession.
     https://forums.developer.apple.com/message/199637#199637
     https://forums.developer.apple.com/thread/11554
     */
    fileprivate func synchroniseURLSession() {
        assert(orderlyQueue.onDispatchQueue)
        urlSession.getTasksWithCompletionHandler { _, _, downloadTasks in
            self.synchroniseDownloadTasks(downloadTasks: downloadTasks)
            self.createDownloadTasksForIdleFileResources()
        }
    }

    fileprivate func transitionFromIdle(fileResource: FileResource) {
        if case let .idle(idle) = fileResource.internalState {
            let downloadTask: URLSessionDownloadTask
            if let resumable = idle.resumable {
                downloadTask = urlSession.downloadTask(withResumeData: resumable.resumeData)
            } else {
                var urlRequest = try! URLRequest(url: fileResource.remoteURL, method: .get)
                fileResourceController?.authenticationController.applyAuthToURLRequest(urlRequest: &urlRequest)
                downloadTask = urlSession.downloadTask(with: urlRequest)
            }
            fileResource.internalState = .downloading(FileResource.InternalState.Downloading(task: downloadTask, downloadedSizeInBytes: fileResource.internalState.finalOrDownloadedSizeInBytes))
            downloadTask.resume()
        }
    }

    // MARK: private Downloader

    private let log = OSLog()
    private weak var fileResourceController: FileResourceController?
    private let cryptController: CryptController
    private let orderlyQueue: MarkedDispatchQueue
    private var urlSession: URLSession!

    /**
     Makes the file resources consistent with the download tasks, via adjustment of the internal state
     of file resources to match the given tasks.
     Also, tasks may be cancelled if no FileResource is found. No tasks are created.
     */
    private func synchroniseDownloadTasks(downloadTasks: [URLSessionDownloadTask]) {
        assert(orderlyQueue.onDispatchQueue)
        guard let fileResourceController = fileResourceController else { return }
        for downloadTask in downloadTasks {
            guard let remoteURL = downloadTask.originalRequest?.url else { continue }
            if let fileResource = fileResourceController.fileResourcesById[remoteURL]?.fileResource {
                switch fileResource.internalState {
                case .idle, .downloading:
                    fileResource.internalState = .downloading(FileResource.InternalState.Downloading(task: downloadTask, downloadedSizeInBytes: fileResource.internalState.finalOrDownloadedSizeInBytes))
                    downloadTask.resume() // no idea why they'd ever be suspended, but hey ho
                case .downloaded:
                    // Pointless continuing to download it
                    downloadTask.cancel()
                }
            } else {
                // We don't know anything about this download task
                downloadTask.cancel()
            }
        }
        for weakFileResource in fileResourceController.fileResourcesById.values {
            if let fileResource = weakFileResource.fileResource {
                if case let .downloading(downloading) = fileResource.internalState, downloading.task == nil {
                    // We thought we were downloading this FileResource, but it turns out we're not
                    fileResource.internalState = .idle(FileResource.InternalState.Idle(resumable: nil, lastClientHTTPError: nil))
                }
            }
        }
    }

    private func createDownloadTasksForIdleFileResources() {
        assert(orderlyQueue.onDispatchQueue)
        guard let fileResourceController = fileResourceController else { return }
        for weakFileResource in fileResourceController.fileResourcesById.values {
            if let fileResource = weakFileResource.fileResource {
                transitionFromIdle(fileResource: fileResource)
            }
        }
    }
}
