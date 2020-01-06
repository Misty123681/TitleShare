// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Alamofire
import Apollo
import Foundation

extension ApolloClient {
    internal func fetchWithAuthRetry<Query: GraphQLQuery>(authenticationController: AuthenticationController, query: Query, queue: DispatchQueue = DispatchQueue.main, resultHandler: OperationResultHandler<Query>?) -> Void {
        let retryingResultHandler = authRetryingOperationResultHandler(authenticationController: authenticationController, innerResultHandler: resultHandler) {
            self.fetch(query: query, queue: queue, resultHandler: resultHandler)
        }
        fetch(query: query, queue: queue, resultHandler: retryingResultHandler)
    }

    internal func performWithAuthRetry<Mutation: GraphQLMutation>(authenticationController: AuthenticationController, mutation: Mutation, queue: DispatchQueue = DispatchQueue.main, resultHandler: OperationResultHandler<Mutation>?) -> Void {
        let retryingResultHandler = authRetryingOperationResultHandler(authenticationController: authenticationController, innerResultHandler: resultHandler) {
            self.perform(mutation: mutation, queue: queue, resultHandler: resultHandler)
        }
        perform(mutation: mutation, queue: queue, resultHandler: retryingResultHandler)
    }
}

fileprivate typealias ResultHandler<T> = (_ result: GraphQLResult<T>?, _ error: Error?) -> Void

fileprivate func authRetryingOperationResultHandler<T>(authenticationController: AuthenticationController, innerResultHandler: ResultHandler<T>?, retrier: @escaping () -> Void) -> ResultHandler<T> {
    return { result, error in
        if isUnauthenticated(result: result, error: error) {
            // Attempt to login again from the keychain
            authenticationController.attemptLoginFromKeyChain { loginError in
                if loginError == nil {
                    // Try again
                    retrier()
                } else {
                    innerResultHandler?(result, error)
                }
            }
        } else {
            innerResultHandler?(result, error)
        }
    }
}

fileprivate func isUnauthenticated<Data>(result: GraphQLResult<Data>?, error: Error?) -> Bool {
    return (result?.data == nil && result?.hasErrorWithExtension(code: "UNAUTHENTICATED") ?? false) ||
        (result == nil && (error as? AFError)?.responseCode == 401)
}
