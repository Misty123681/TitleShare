// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation

fileprivate let maximumInconsistentResultRetries = 2

enum ExhaustivelyFetchedAudiobooks {
    case audiobooks([Item])
    case networkError
    case serverError

    typealias Item = ContentItemsQuery.Data.SearchContent.Item
}

func exhaustivelyFetchUserAudiobooks(apolloClient: ApolloClient, authenticationController: AuthenticationController, handler: @escaping (ExhaustivelyFetchedAudiobooks) -> Void) {
    typealias Item = ExhaustivelyFetchedAudiobooks.Item

    enum FetchedAudiobooksPage {
        case audiobooks(items: [Item], totalCount: Int)
        case networkError
        case serverError
    }

    func fetchPage(oneBasedPageNumber: Int, pageHandler: @escaping (FetchedAudiobooksPage) -> Void) {
        apolloClient.fetchWithAuthRetry(authenticationController: authenticationController, query: ContentItemsQuery(pageSize: 20, oneBasedPageNumber: oneBasedPageNumber, coverImageSizes: [ImageSizeInput(height: 256, width: 256), ImageSizeInput(height: 1024, width: 1024)])) { result, _ in
            guard let result = result else {
                pageHandler(.networkError)
                return
            }
            guard let data = result.data else {
                pageHandler(.serverError)
                return
            }
            pageHandler(.audiobooks(items: data.searchContent.items, totalCount: data.searchContent.totalCount))
        }
    }

    func fetchAllPages(oneBasedPageNumber: Int, previousItems: [Item], previousTotalItems: Int?, inconsistentResultRetryCount: Int) {
        fetchPage(oneBasedPageNumber: oneBasedPageNumber) { fetchedItemsPage in
            switch fetchedItemsPage {
            case let .audiobooks(items, totalItems):
                if let previousTotalItems = previousTotalItems {
                    if totalItems != previousTotalItems {
                        // Hmmm, the server is now reporting a different number of total audiobooks...
                        // probably caused by a server-side mutation concurrent with our exhaustive fetch
                        // Reset everything and try again
                        if inconsistentResultRetryCount <= maximumInconsistentResultRetries {
                            fetchAllPages(oneBasedPageNumber: 1, previousItems: [], previousTotalItems: nil, inconsistentResultRetryCount: inconsistentResultRetryCount + 1)
                        } else {
                            // So slim an edge case that we (ab)use the server error variant
                            handler(.serverError)
                        }
                        return
                    }
                }
                let accumulatedItems = previousItems + items
                if accumulatedItems.count < totalItems {
                    fetchAllPages(oneBasedPageNumber: oneBasedPageNumber + 1, previousItems: accumulatedItems, previousTotalItems: totalItems, inconsistentResultRetryCount: inconsistentResultRetryCount)
                } else {
                    handler(.audiobooks(accumulatedItems))
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

    fetchAllPages(oneBasedPageNumber: 1, previousItems: [], previousTotalItems: nil, inconsistentResultRetryCount: 0)
}
