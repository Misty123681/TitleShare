// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation

/**
 Provides access to the user's audiobooks.
 */
class UserAudiobooks {
    struct Audiobooks {
        let items: [Audiobook]
        let dateFetched: Date
    }

    enum LastFetchError {
        case networkError(dateFetched: Date)
        case serverError(dateFetched: Date)
    }

    struct State {
        var audiobooks: Audiobooks?
        var fetching: Bool
        var lastFetchError: LastFetchError?
    }

    private let audiobooksController: AudiobooksController
    private let audiobookRegistry: AudiobookRegistry
    private let fileResourceController: FileResourceController
    private var mutableState: Watchable<State>.Source = Watchable.Source(value: State(audiobooks: nil, fetching: false, lastFetchError: nil))

    init(from memento: Memento?, audiobooksController: AudiobooksController, audiobookRegistry: AudiobookRegistry, fileResourceController: FileResourceController) {
        self.audiobooksController = audiobooksController
        self.audiobookRegistry = audiobookRegistry
        self.fileResourceController = fileResourceController
        if let memento = memento {
            restore(from: memento, audiobookRegistry: audiobookRegistry)
        }
    }

    public var state: Watchable<State> {
        return mutableState.watchable
    }

    public func refresh() {
        guard !mutableState.value.fetching else { return }
        mutableState.value.fetching = true
        audiobooksController.fetchUserAudiobooks(handler: mergeRefreshResponse)
    }

    private func mergeRefreshResponse(exhaustivelyFetchedAudiobooks: ExhaustivelyFetchedAudiobooks) {
        assert(mutableState.value.fetching)
        var state = mutableState.value
        let now = Date()
        switch exhaustivelyFetchedAudiobooks {
        case let .audiobooks(graphqlAudiobooks):
            let newAudiobooks = graphqlAudiobooks.map({ graphqlAudiobook -> Audiobook in
                let id = graphqlAudiobook.id
                let metadata = AudiobookMetadata(graphql: graphqlAudiobook)
                if let existingAudiobook = self.audiobookRegistry.audiobook(id: id) {
                    existingAudiobook.update(metadata: metadata)
                    return existingAudiobook
                } else {
                    return Audiobook(id: id, metadata: metadata, audiobooksController: self.audiobooksController, audiobookRegistry: self.audiobookRegistry, fileResourceController: self.fileResourceController)
                }
            })
            state.audiobooks = Audiobooks(items: newAudiobooks, dateFetched: now)
            state.lastFetchError = nil
        case .networkError:
            state.lastFetchError = .networkError(dateFetched: now)
        case .serverError:
            state.lastFetchError = .serverError(dateFetched: now)
        }
        state.fetching = false
        mutableState.value = state
    }
}

extension UserAudiobooks {
    struct Memento: Codable {
        let audiobooks: [Audiobook.Id]?
        let dateFetched: Date?
    }

    var memento: Memento {
        if let audiobooks = mutableState.value.audiobooks {
            return Memento(audiobooks: audiobooks.items.map({ $0.id }), dateFetched: audiobooks.dateFetched)
        } else {
            return Memento(audiobooks: nil, dateFetched: nil)
        }
    }

    fileprivate func restore(from memento: Memento, audiobookRegistry: AudiobookRegistry) {
        if let audiobooks = memento.audiobooks, let dateFetched = memento.dateFetched {
            mutableState.value = State(audiobooks: Audiobooks(items: audiobooks.compactMap(audiobookRegistry.audiobook), dateFetched: dateFetched), fetching: false, lastFetchError: nil)
        } else {
            mutableState.value = State(audiobooks: nil, fetching: false, lastFetchError: nil)
        }
    }
}
