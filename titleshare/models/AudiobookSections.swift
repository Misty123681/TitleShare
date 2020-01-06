// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation

class AudiobookSections {
    public enum Progress {
        case waitingForMetadata
        case downloading(bytesDownloaded: Int64, bytesTotal: Int64)
        case complete
    }

    private let audiobooksController: AudiobooksController
    private let fileResourceController: FileResourceController
    private let audiobookId: Audiobook.Id?
    private let _items: Watchable<[AudiobookSection]?>.Source
    private var _audioSectionsHash: String?
    private var totalBytes: Int64?
    private let _progress: Watchable<Progress>.Source = Watchable.Source(value: .waitingForMetadata)
    private let resources = Resource()

    init(from memento: Memento, audiobooksController: AudiobooksController, fileResourceController: FileResourceController) {
        self.audiobooksController = audiobooksController
        self.fileResourceController = fileResourceController
        switch memento.state {
        case let .noSections(noSections):
            audiobookId = noSections.audiobookId
            _items = Watchable.Source(value: nil)
            _audioSectionsHash = nil
            totalBytes = nil
            fetchAudiobookSections(audiobookId: noSections.audiobookId)
        case let .sections(sections):
            audiobookId = nil
            _items = Watchable.Source(value: sections.items.map({ AudiobookSection(from: $0, fileResourceController: fileResourceController) }))
            _audioSectionsHash = sections.audioSectionsHash
            totalBytes = sections.totalBytes
            watchFileResources()
        }
    }

    init(audiobookId: String, audiobooksController: AudiobooksController, fileResourceController: FileResourceController) {
        self.audiobooksController = audiobooksController
        self.fileResourceController = fileResourceController
        self.audiobookId = audiobookId
        _items = Watchable.Source(value: nil)
        _audioSectionsHash = nil
        totalBytes = nil

        fetchAudiobookSections(audiobookId: audiobookId)
    }

    public var items: Watchable<[AudiobookSection]?> {
        return _items.watchable
    }
    
    public var audioSectionsHash: String? {
        return _audioSectionsHash;
    }

    public var progress: Watchable<Progress> {
        return _progress.watchable
    }

    func stale(latestAudioSectionHash: String) -> Bool {
        return audioSectionsHash.map({ $0 != latestAudioSectionHash }) ?? false
    }

    private func fetchAudiobookSections(audiobookId: String) {
        audiobooksController.fetchAudiobookSections(contentItemId: audiobookId, handler: fetchAudiobookSectionsHandler)
    }

    private enum FetchResponseError: Error {
        case unexpectedContent(String)
    }

    private func fetchAudiobookSectionsHandler(exhaustivelyFetchedAudiobooks: ExhaustivelyFetchedAudiobookSections) {
        switch exhaustivelyFetchedAudiobooks {
        case let .sections(sections, audioSectionsHash, totalBytes):
            _items.value = sections.compactMap({
                // For now, we ignore and exclude sections that are ill-formed
                try? self.audiobookSectionFromFetchedItem(item: $0)
            })
            self._audioSectionsHash = audioSectionsHash
            self.totalBytes = totalBytes
            watchFileResources()
        case .serverError:
            // TODO: schedule a retry at a future time, with backoff?
            ()
        case .networkError:
            // TODO: schedule a retry at a future time, with backoff, perhaps when connectivity improves?
            ()
        }
    }

    private func audiobookSectionFromFetchedItem(item: ExhaustivelyFetchedAudiobookSections.Item) throws -> AudiobookSection {
        guard let narrationRemoteURL = URL(string: item.narrationUri.uri) else { throw FetchResponseError.unexpectedContent("narrationUri cannot be parsed as a URL") }
        let soundtrackRemoteURL = try (item.soundtrackUri?.uri).map({ uri -> URL in
            guard let url = URL(string: uri) else { throw FetchResponseError.unexpectedContent("soundtrackUri cannot be parsed as a URL") }
            return url
        })
        return AudiobookSection(title: item.title, narrationRemoteURL: narrationRemoteURL, soundtrackRemoteURL: soundtrackRemoteURL, fileResourceController: fileResourceController)
    }

    private func watchFileResources() {
        let items = _items.value!
        synchroniseProgress()
        let weakSynchroniseProgress: (FileResource.State) -> Void = { [weak self] _ in
            self?.synchroniseProgress()
        }
        for item in items {
            resources.aggregate(resource: item.narrationFileResource.state.watch(invokeNow: false, watchHandler: weakSynchroniseProgress))
            if let fileResource = item.soundtrackFileResource {
                resources.aggregate(resource: fileResource.state.watch(invokeNow: false, watchHandler: weakSynchroniseProgress))
            }
        }
    }

    private func synchroniseProgress() {
        let items = _items.value!
        let (bytesDownloaded, allComplete): (Int64, Bool) = items.reduce((0, true)) {
            let narrationState: FileResource.State = $1.narrationFileResource.state.value
            let soundtrackState: FileResource.State? = $1.soundtrackFileResource?.state.value
            return ($0.0 + narrationState.finalOrDownloadedSizeInBytes + (soundtrackState?.finalOrDownloadedSizeInBytes ?? 0), $0.1 && narrationState.available && (soundtrackState?.available ?? true))
        }
        if allComplete {
            _progress.value = .complete
        } else {
            _progress.value = .downloading(bytesDownloaded: bytesDownloaded, bytesTotal: totalBytes!)
        }
    }
}

extension AudiobookSections {
    struct Memento: Codable {
        let state: State

        enum State: Codable {
            case noSections(NoSections)
            case sections(Sections)

            struct NoSections: Codable {
                let audiobookId: Audiobook.Id
            }

            struct Sections: Codable {
                let audioSectionsHash: String
                let items: [AudiobookSection.Memento]
                let totalBytes: Int64
            }

            private enum CodingKeys: String, CodingKey {
                case pendingSectionMetadata
                case sections
            }

            private enum CodingError: Error {
                case decoding(String)
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                guard let key = container.allKeys.first else { throw CodingError.decoding("No valid keys in: \(container)") }
                func decode<T: Decodable>() throws -> T { return try container.decode(T.self, forKey: key) }
                switch key {
                case .pendingSectionMetadata:
                    self = .noSections(try decode())
                case .sections:
                    self = .sections(try decode())
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case let .noSections(associatedValue):
                    try container.encode(associatedValue, forKey: .pendingSectionMetadata)
                case let .sections(associatedValue):
                    try container.encode(associatedValue, forKey: .sections)
                }
            }
        }
    }

    var memento: Memento {
        if let items = _items.value, let audioSectionHash = audioSectionsHash, let totalBytes = totalBytes {
            return Memento(state: .sections(AudiobookSections.Memento.State.Sections(audioSectionsHash: audioSectionHash, items: items.map({ $0.memento }), totalBytes: totalBytes)))
        } else {
            return Memento(state: .noSections(AudiobookSections.Memento.State.NoSections(audiobookId: audiobookId!)))
        }
    }
}
