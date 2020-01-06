// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

enum AudiobookCellViewModelDelegateRemoveAction {
    case cancelDownloadAndRemoveFromDevice(() -> Void)
    case removeFromDevice(() -> Void)
}

protocol AudiobookCellViewModelDelegate: class {
    func presentAudiobookDetails(audiobook: Audiobook)
    func presentAudiobookPlayer(audiobook: Audiobook)
    func confirmAudiobookAction(originatingLocation: OriginatingLocation, removeAction: AudiobookCellViewModelDelegateRemoveAction, updateAction: (() -> Void)?)
}

class AudiobookCellViewModel {
    struct State {
        let secondaryAction: SecondaryAction
        let downloadingButPlayable: Bool
        let downloadedAndUpdatable: Bool
        let progress: Double?
        fileprivate let downloadable: Bool
        fileprivate let removable: Bool
        fileprivate let playability: Playability

        fileprivate enum Playability {
            case notPlayable
            case partiallyPlayable
            case playable
        }

        enum SecondaryAction {
            case download
            case remove
            case more
        }
    }

    private let audiobook: Audiobook
    private weak var delegate: AudiobookCellViewModelDelegate?
    private let _title: Watchable<String>.Source
    private let _state: Watchable<State>.Source
    private let resources = Resource()
    private var audiobookSectionsResource: Resource?

    init(audiobook: Audiobook, delegate: AudiobookCellViewModelDelegate) {
        self.audiobook = audiobook
        self.delegate = delegate
        _title = Watchable.Source(value: audiobook.metadata.value.title)
        resources.aggregate(resource: audiobook.metadata.watch(invokeNow: false) { [_title] in
            _title.value = $0.title
        })
        _state = Watchable.Source(value: /* initial dummy value will be replaced before init returns */ State(secondaryAction: .download, downloadingButPlayable: false, downloadedAndUpdatable: false, progress: nil, downloadable: false, removable: false, playability: .notPlayable))
        resources.aggregate(resource: audiobook.audiobookSections.watch(invokeNow: true) { [weak self] in
            guard let self = self else { return }
            if let audiobookSections = $0 {
                self.audiobookSectionsResource = audiobookSections.progress.watch(invokeNow: false) { [weak self] _ in
                    guard let self = self else { return }
                    self.synchroniseState()
                }
            } else {
                self.audiobookSectionsResource = nil
                self.synchroniseState()
            }
        })
        resources.aggregate(resource: audiobook.audiobookSectionsUpdateAvailable.watch(invokeNow: true) { [weak self] _ in
            guard let self = self else { return }
            self.synchroniseState()
        })
    }

    var title: Watchable<String> {
        return _title.watchable
    }

    var coverImageFileResource: Watchable<FileResource?> {
        return audiobook.smallCoverImageFileResource
    }

    var state: Watchable<State> {
        return _state.watchable
    }

    func performPrimaryAction() {
        let state = _state.value
        if state.downloadable {
            audiobook.fetchAudiobookSections()
        } else if state.playability != .notPlayable {
            delegate?.presentAudiobookPlayer(audiobook: audiobook)
        } else {
            // should be unreachable, but might as well have a sensible default
            presentAudiobookDetails()
        }
    }

    func performSecondaryAction(originatingLocation: OriginatingLocation) {
        let audiobook = self.audiobook
        switch _state.value.secondaryAction {
        case .download:
            audiobook.fetchAudiobookSections()
        case .remove:
            let downloading = _state.value.progress != nil
            if downloading {
                delegate?.confirmAudiobookAction(originatingLocation: originatingLocation, removeAction: .cancelDownloadAndRemoveFromDevice(self.audiobook.removeAudiobookSections), updateAction: nil)
            } else {
                delegate?.confirmAudiobookAction(originatingLocation: originatingLocation, removeAction: .removeFromDevice(self.audiobook.removeAudiobookSections), updateAction: nil)
            }
        case .more:
            delegate?.confirmAudiobookAction(originatingLocation: originatingLocation, removeAction: .removeFromDevice(self.audiobook.removeAudiobookSections), updateAction: self.audiobook.updateAudiobookSections)
        }
    }

    func presentAudiobookDetails() {
        delegate?.presentAudiobookDetails(audiobook: audiobook)
    }

    private func synchroniseState() {
        _state.value = extractState()
    }

    private func extractState() -> State {
        let secondaryAction: State.SecondaryAction
        let incompleteButPlayable: Bool
        var downloadedAndUpdatable: Bool
        var progress: Double?
        var downloadable: Bool
        var removable: Bool
        var playability: State.Playability

        if let audiobookSections = audiobook.audiobookSections.value {
            downloadable = false
            removable = true
            switch audiobookSections.progress.value {
            case .waitingForMetadata:
                secondaryAction = .remove
                incompleteButPlayable = false
                downloadedAndUpdatable = false
                progress = 0
                playability = .notPlayable
            case let .downloading(bytesDownloaded: bytesDownloaded, bytesTotal: bytesTotal):
                secondaryAction = .remove
                downloadedAndUpdatable = false
                progress = Double(bytesDownloaded) / Double(bytesTotal)
                let partiallyPlayable = audiobookSections.items.value?.first.map({
                    $0.narrationFileResource.state.value.available && ($0.soundtrackFileResource?.state.value.available ?? true)
                }) ?? false
                playability = partiallyPlayable ? .partiallyPlayable : .notPlayable
                incompleteButPlayable = partiallyPlayable
            case .complete:
                // legacy app only allowed updating when fully downloaded,
                // we mimic that behaviour despite our model supporting updating in any of the states in this switch
                downloadedAndUpdatable = audiobook.audiobookSectionsUpdateAvailable.value
                secondaryAction = downloadedAndUpdatable ? .more : .remove
                incompleteButPlayable = false
                progress = nil
                playability = .playable
            }
        } else {
            secondaryAction = .download
            incompleteButPlayable = false
            downloadable = true
            downloadedAndUpdatable = false
            removable = false
            progress = nil
            playability = .notPlayable
        }

        return State(secondaryAction: secondaryAction, downloadingButPlayable: incompleteButPlayable, downloadedAndUpdatable: downloadedAndUpdatable, progress: progress, downloadable: downloadable, removable: removable, playability: playability)
    }
}
