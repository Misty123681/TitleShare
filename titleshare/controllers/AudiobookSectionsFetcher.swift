// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation

fileprivate let maximumInconsistentResultRetries = 2

enum ExhaustivelyFetchedAudiobookSections {
    case sections(items: [Item], audioSectionsHash: String, totalBytes: Int64)
    case networkError
    case serverError

    typealias Item = ContentItemAudioSectionsQuery.Data.Node.AsContent.AudioSection.Item
}

func exhaustivelyFetchAudiobookSections(contentItemId: String, apolloClient: ApolloClient, authenticationController: AuthenticationController, handler: @escaping (ExhaustivelyFetchedAudiobookSections) -> Void) {
    typealias Item = ExhaustivelyFetchedAudiobookSections.Item

    enum FetchedAudiobookSectionsPage {
        case sections(items: [Item], totalCount: Int, hash: String, totalBytes: Int64)
        case networkError
        case serverError
    }

    func fetchPage(oneBasedPageNumber: Int, pageHandler: @escaping (FetchedAudiobookSectionsPage) -> Void) {
        apolloClient.fetchWithAuthRetry(authenticationController: authenticationController, query: ContentItemAudioSectionsQuery(contentItemId: contentItemId, pageSize: 20, oneBasedPageNumber: oneBasedPageNumber)) { result, _ in
            guard let result = result else {
                pageHandler(.networkError)
                return
            }
            guard let contentItem = result.data?.node?.asContent else {
                pageHandler(.serverError)
                return
            }
            pageHandler(.sections(items: contentItem.audioSections.items, totalCount: contentItem.audioSections.totalCount, hash: contentItem.audioSectionsHash, totalBytes: contentItem.totalBytes.total))
        }
    }

    func fetchAllPages(oneBasedPageNumber: Int, previousItems: [Item], previousTotalItems: Int?, previousHash: String?, inconsistentResultRetryCount: Int) {
        fetchPage(oneBasedPageNumber: oneBasedPageNumber) { fetchedItemsPage in
            switch fetchedItemsPage {
            case let .sections(items, totalItems, hash, totalBytes):
                if let previousTotalItems = previousTotalItems, let previousHash = previousHash {
                    if totalItems != previousTotalItems || hash != previousHash {
                        // Hmmm, the server is now reporting a different number of total items/hash...
                        // probably caused by a server-side mutation concurrent with our exhaustive fetch
                        // Reset everything and try again
                        if inconsistentResultRetryCount <= maximumInconsistentResultRetries {
                            fetchAllPages(oneBasedPageNumber: 1, previousItems: [], previousTotalItems: nil, previousHash: nil, inconsistentResultRetryCount: inconsistentResultRetryCount + 1)
                        } else {
                            // So slim an edge case that we (ab)use the server error variant
                            handler(.serverError)
                        }
                        return
                    }
                }
                let accumulatedItems = previousItems + items
                if accumulatedItems.count < totalItems {
                    fetchAllPages(oneBasedPageNumber: oneBasedPageNumber + 1, previousItems: accumulatedItems, previousTotalItems: totalItems, previousHash: hash, inconsistentResultRetryCount: inconsistentResultRetryCount)
                } else {
                    handler(.sections(items: accumulatedItems, audioSectionsHash: hash, totalBytes: totalBytes))
                }
                return
            case .networkError:
                handler(.networkError)
                return
            case .serverError:
                handler(.serverError)
                return
            }
        }
    }

    fetchAllPages(oneBasedPageNumber: 1, previousItems: [], previousTotalItems: nil, previousHash: nil, inconsistentResultRetryCount: 0)
}
