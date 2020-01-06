// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation

class Audiobook: Equatable, Hashable {
    typealias Id = String

    private let audiobooksController: AudiobooksController
    private let audiobookRegistry: AudiobookRegistry
    private let fileResourceController: FileResourceController
    private let _metadata: Watchable<AudiobookMetadata>.Source
    private let _smallCoverImageFileResource: Watchable<FileResource?>.Source
    private let _largeCoverImageFileResource: Watchable<FileResource?>.Source
    private let _bookmark: Watchable<Bookmark?>.Source
    private let _playbackRegions: Watchable<[AudiobookPlaybackRegion]?>.Source
    private let _audiobookSections: Watchable<AudiobookSections?>.Source
    private let _audiobookSectionsUpdateAvailable: Watchable<Bool>.Source = Watchable.Source(value: false)
    public let id: Id

    init(from memento: Memento, audiobooksController: AudiobooksController, audiobookRegistry: AudiobookRegistry, fileResourceController: FileResourceController) {
        id = memento.id
        _metadata = Watchable.Source(value: memento.metadata)
        _smallCoverImageFileResource = Watchable.Source(value: memento.smallCoverImageRemoteURL.map({ fileResourceController.fileResource(remoteURL: $0, encrypted: false) }))
        _largeCoverImageFileResource = Watchable.Source(value: memento.largeCoverImageRemoteURL.map({ fileResourceController.fileResource(remoteURL: $0, encrypted: false) }))
        _bookmark = Watchable.Source(value: memento.bookmark)
        _playbackRegions = Watchable.Source(value: memento.playback)
        _audiobookSections = Watchable.Source(value: memento.audiobookSections.map({ AudiobookSections(from: $0, audiobooksController: audiobooksController, fileResourceController: fileResourceController) }))
        self.audiobooksController = audiobooksController
        self.audiobookRegistry = audiobookRegistry
        self.fileResourceController = fileResourceController
        synchroniseAudiobookSectionsUpdateAvailable()
        audiobookRegistry.remember(audiobook: self)
    }

    init(id: Id, metadata: AudiobookMetadata, audiobooksController: AudiobooksController, audiobookRegistry: AudiobookRegistry, fileResourceController: FileResourceController) {
        self.id = id
        _metadata = Watchable.Source(value: metadata)
        _smallCoverImageFileResource = Watchable.Source(value: metadata.coverImageUrl256x256.map({ fileResourceController.fileResource(remoteURL: $0, encrypted: false) }))
        _largeCoverImageFileResource = Watchable.Source(value: nil)
        _bookmark = Watchable.Source(value: nil)
        _playbackRegions = Watchable.Source(value: nil)
        _audiobookSections = Watchable.Source(value: nil)
        self.audiobooksController = audiobooksController
        self.audiobookRegistry = audiobookRegistry
        self.fileResourceController = fileResourceController
        synchroniseAudiobookSectionsUpdateAvailable()
        audiobookRegistry.remember(audiobook: self)
    }

    deinit {
        audiobookRegistry.forget(audiobook: self)
    }

    public var metadata: Watchable<AudiobookMetadata> {
        return _metadata.watchable
    }

    /**
     The small cover image.

     The image may change if the audiobook is updated.
     */
    public var smallCoverImageFileResource: Watchable<FileResource?> {
        return _smallCoverImageFileResource.watchable
    }

    /**
     The large cover image.

     The image may change if the audiobook is updated.
     */
    public var largeCoverImageFileResource: Watchable<FileResource?> {
        return _largeCoverImageFileResource.watchable
    }

    public func fetchLargeCoverImage() {
        _largeCoverImageFileResource.value = _metadata.value.coverImageUrl1024x1024.map({ fileResourceController.fileResource(remoteURL: $0, encrypted: false) })
    }

    /**
     The user's bookmark
     */
    public var bookmark: Watchable<Bookmark?> {
        return _bookmark.watchable
    }

    public func fetchBookmark(callback: @escaping (_ bookmark: Bookmark?) -> Void) {
        audiobooksController.fetchBookmark(id) { [weak self] bookmark in
            if let bookmark = bookmark {
                self?._bookmark.value = bookmark
                callback(bookmark)
            } else {
                self?._bookmark.value = nil
                callback(nil)
            }
        }
    }

    public func logPlayback(for playbackRegions: [AudiobookPlaybackRegion]) {
        if playbackRegions.count == 0 { return }

        audiobooksController.logPlaybackAccessQueue.async {
            if var existingRegions = self._playbackRegions.value {
                existingRegions.append(contentsOf: playbackRegions)
                self._playbackRegions.value = existingRegions

            } else {
                self._playbackRegions.value = playbackRegions
            }
        }

        sendPlaybackLogsToServer()

        let latestRegion = playbackRegions.sorted {
            $0.endTimestamp > $1.endTimestamp
        }.first

        if let latestRegion = latestRegion {
            // Update the local bookmark
            _bookmark.value = Bookmark(audioSectionIndex: latestRegion.audioSectionIndex, time: latestRegion.endTime)
        }
    }

    public func sendPlaybackLogsToServer() {
        audiobooksController.logPlaybackAccessQueue.async {
            guard let playbackRegions = self._playbackRegions.value else { return }

            // clear the playback regions, assuming the request to the server will succeed.
            self._playbackRegions.value = nil
            self.audiobooksController.sendPlaybackLogsToServer(contentId: self.id, playbackRegions: playbackRegions) { [weak self, playbackRegions] success in
                if !success {
                    // If there is an error sending the logs to the server, add the playback regions back to the audiobook so they can be tried later
                    if var existingRegions = self?._playbackRegions.value {
                        existingRegions.append(contentsOf: playbackRegions)
                        self?._playbackRegions.value = existingRegions

                    } else {
                        self?._playbackRegions.value = playbackRegions
                    }
                }
            }
        }
    }

    public func fetchAudiobookSections() {
        guard _audiobookSections.value == nil else { return }
        _audiobookSections.value = AudiobookSections(audiobookId: id, audiobooksController: audiobooksController, fileResourceController: fileResourceController)
    }

    public func updateAudiobookSections() {
        guard _audiobookSectionsUpdateAvailable.value else { return }
        _audiobookSections.value = AudiobookSections(audiobookId: id, audiobooksController: audiobooksController, fileResourceController: fileResourceController)
        synchroniseAudiobookSectionsUpdateAvailable()
    }

    public func removeAudiobookSections() {
        _audiobookSections.value = nil
        synchroniseAudiobookSectionsUpdateAvailable()
    }

    public var audiobookSections: Watchable<AudiobookSections?> {
        return _audiobookSections.watchable
    }

    /**
     Whether there are updated audiobook sections available for download.
     */
    public var audiobookSectionsUpdateAvailable: Watchable<Bool> {
        return _audiobookSectionsUpdateAvailable.watchable
    }

    func update(metadata: AudiobookMetadata) {
        let oldCoverImageUrl256x256 = _metadata.value.coverImageUrl256x256
        let oldCoverImageUrl1024x1024 = _metadata.value.coverImageUrl1024x1024

        _metadata.value = metadata

        if metadata.coverImageUrl256x256 != oldCoverImageUrl256x256 {
            _smallCoverImageFileResource.value = metadata.coverImageUrl256x256.map({ fileResourceController.fileResource(remoteURL: $0, encrypted: false) })
        }

        if metadata.coverImageUrl1024x1024 != oldCoverImageUrl1024x1024 {
            _largeCoverImageFileResource.value = nil
        }

        synchroniseAudiobookSectionsUpdateAvailable()
    }

    func synchroniseAudiobookSectionsUpdateAvailable() {
        _audiobookSectionsUpdateAvailable.value = _audiobookSections.value?.stale(latestAudioSectionHash: _metadata.value.audioSectionsHash) ?? false
    }

    static func == (lhs: Audiobook, rhs: Audiobook) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Audiobook {
    struct Memento: Codable {
        let id: String
        let metadata: AudiobookMetadata
        let smallCoverImageRemoteURL: URL?
        let largeCoverImageRemoteURL: URL?
        let bookmark: Bookmark?
        let playback: [AudiobookPlaybackRegion]?
        let audiobookSections: AudiobookSections.Memento?
    }

    var memento: Memento {
        return Memento(id: id, metadata: _metadata.value, smallCoverImageRemoteURL: _smallCoverImageFileResource.value?.remoteURL, largeCoverImageRemoteURL: _largeCoverImageFileResource.value?.remoteURL, bookmark: _bookmark.value, playback: _playbackRegions.value, audiobookSections: _audiobookSections.value?.memento)
    }
}

struct Bookmark: Codable {
    let audioSectionIndex: Int
    let time: Double
}
