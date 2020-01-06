// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

struct Audiobooks {
    let items: [AudiobookCellViewModel]
    let dateFetched: Date?
}

protocol AudiobooksCollectionViewModel {
    var showSectionHeader: Bool { get }
    var audiobooks: Watchable<Audiobooks> { get }
}

class UserCloudAudiobooksCollectionViewModel: AudiobooksCollectionViewModel {
    private var _viewModelTransformer: CachingTransformer<Audiobook, AudiobookCellViewModel>
    private let _audiobooks: Watchable<Audiobooks>.Source = Watchable.Source(value: Audiobooks(items: [], dateFetched: nil))
    private let _resources = Resource()

    init(userAudiobooks: UserAudiobooks, audiobookCellViewModelDelegate: AudiobookCellViewModelDelegate) {
        _viewModelTransformer = CachingTransformer(transform: { AudiobookCellViewModel(audiobook: $0, delegate: audiobookCellViewModelDelegate) })
        _resources.aggregate(resource: userAudiobooks.state.watch(invokeNow: true) { [weak self] state in
            guard let self = self else { return }
            let items = state.audiobooks?.items ?? []
            let dateFetched = state.audiobooks?.dateFetched
            self._audiobooks.value = Audiobooks(items: self._viewModelTransformer.limitMap(items), dateFetched: dateFetched)
        })
    }

    let showSectionHeader = true

    var audiobooks: Watchable<Audiobooks> {
        return _audiobooks.watchable
    }
}

class UserDeviceAudiobooksCollectionViewModel: AudiobooksCollectionViewModel {
    private var _viewModelTransformer: CachingTransformer<Audiobook, AudiobookCellViewModel>
    private let _audiobooks: Watchable<Audiobooks>.Source = Watchable.Source(value: Audiobooks(items: [], dateFetched: nil))
    private let _resources = Resource()
    private var _offlineAvailabilityWatchers: Resource = Resource()

    init(userAudiobooks: UserAudiobooks, audiobookCellViewModelDelegate: AudiobookCellViewModelDelegate) {
        _viewModelTransformer = CachingTransformer(transform: { AudiobookCellViewModel(audiobook: $0, delegate: audiobookCellViewModelDelegate) })

        let assignFilteredAudiobooks = { [weak self] in
            guard let self = self else { return }
            let items = userAudiobooks.state.value.audiobooks?.items ?? []
            let dateFetched = userAudiobooks.state.value.audiobooks?.dateFetched
            self._audiobooks.value = Audiobooks(items: self._viewModelTransformer.limitMap(items.filter({ $0.audiobookSections.value != nil })), dateFetched: dateFetched)
        }

        let offlineAvailabilityDidChange: Watchable<AudiobookSections?>.WatchHandler = { _ in
            assignFilteredAudiobooks()
        }

        _resources.aggregate(resource: userAudiobooks.state.watch(invokeNow: true) { [weak self] state in
            guard let self = self else { return }
            self._offlineAvailabilityWatchers = Resource()
            for audiobook in state.audiobooks?.items ?? [] {
                self._offlineAvailabilityWatchers.aggregate(resource: audiobook.audiobookSections.watch(invokeNow: false, watchHandler: offlineAvailabilityDidChange))
            }
            assignFilteredAudiobooks()
        })
    }

    let showSectionHeader = false

    var audiobooks: Watchable<Audiobooks> {
        return _audiobooks.watchable
    }
}
