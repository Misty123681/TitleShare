// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import os

/**
 Provides access to remote audiobook related data
 */
class AudiobooksController {
    private let _apolloClient: ApolloClient
    private let _log = OSLog()
    private let _authenticationController: AuthenticationController
    private let _logPlaybackAccessQueue = DispatchQueue(label: "logPlaybackAccessQueue")

    public init(apolloClient: ApolloClient, authenticationController: AuthenticationController) {
        _apolloClient = apolloClient
        _authenticationController = authenticationController
    }

    internal func fetchAudiobookSections(contentItemId: String, handler: @escaping (ExhaustivelyFetchedAudiobookSections) -> Void) {
        exhaustivelyFetchAudiobookSections(contentItemId: contentItemId, apolloClient: _apolloClient, authenticationController: _authenticationController, handler: handler)
    }

    internal func fetchUserAudiobooks(handler: @escaping (ExhaustivelyFetchedAudiobooks) -> Void) {
        exhaustivelyFetchUserAudiobooks(apolloClient: _apolloClient, authenticationController: _authenticationController, handler: handler)
    }

    /**
     A single dispatch queue for managing playback logs for all audiobooks (to avoid a dispatch queue instance for each audiobook)
     */
    internal var logPlaybackAccessQueue: DispatchQueue {
        return _logPlaybackAccessQueue
    }

    internal func fetchBookmark(_ contentId: String, resultHandler: @escaping (_ bookmark: Bookmark?) -> Void) {
        _apolloClient.fetchWithAuthRetry(authenticationController: _authenticationController, query: MyBookmarkQuery(contentId: contentId)) { result, _ in
            if let bookmark = result?.data?.node?.asContent?.myBookmark {
                let bm = Bookmark(audioSectionIndex: bookmark.audioSectionIndex, time: bookmark.time)
                resultHandler(bm)
            } else {
                resultHandler(nil)
            }
        }
    }

    /**
     Sends the playback regions to the server.

     Note that the result hander will be called on the logPlaybackAccessQueue dispatch queue
     */
    internal func sendPlaybackLogsToServer(contentId: String, playbackRegions: [AudiobookPlaybackRegion], resultHander: @escaping (_ success: Bool) -> Void) {
        let apiPlaybackRegions = playbackRegions.map({ PlaybackRegion(
            audioSectionsHash: $0.audioSectionsHash,
            audioSectionIndex: $0.audioSectionIndex,
            startTime: $0.startTime,
            endTime: $0.endTime,
            endTimestamp: $0.endTimestamp
        ) })

        _apolloClient.perform(mutation: LogPlaybackMutation(contentId: contentId, playbackRegions: apiPlaybackRegions), queue: logPlaybackAccessQueue) { result, error in
            if error != nil || result?.errors != nil {
                resultHander(false)
            } else {
                resultHander(true)
            }
        }
    }
}
