// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import os
import UIKit

enum LoginError {
    case cancelled
    case networkError
    case serverError
    case invalidCredentials
}

enum SignUpResult {
    case cancelled
    case networkError
    case serverError
    case invalidCode
    case forbidden
    case successButMustLogin
    case successButMustSetPassword
    case success
}

enum RequestError {
    case cancelled
    case networkError
    case serverError
}

/**
 Controls all aspects of logging in and out of users.

 This class is intended to be a singleton which is injected where needed.
 */
class AuthenticationController {
    private let _alamofireApolloTransport: AlamofireApolloTransport
    private let _apollo: ApolloClient
    private let _appData: AppDataController
    private var _loginCancellationToken: CancellationToken?
    private var _signUpCancellationToken: CancellationToken?
    private var _resetPasswordCancellationToken: CancellationToken?

    public init(alamofireApolloTransport: AlamofireApolloTransport, apollo: ApolloClient, appData: AppDataController) {
        _alamofireApolloTransport = alamofireApolloTransport
        _apollo = apollo
        _appData = appData
        applyAuthToGraphQLTransport()
    }

    public func login(email: String, password: String, saveInKeyChain: Bool, resultHandler: @escaping (_ error: LoginError?) -> Void) {
        _appData.userAuthToken = nil
        applyAuthToGraphQLTransport()
        _loginCancellationToken?.cancel()
        let cancellationToken = CancellationToken()
        let cancellable = _apollo.perform(mutation: LoginUserMutation(email: email, password: password)) { result, _ in
            assert(Thread.isMainThread)
            if cancellationToken.cancelled {
                resultHandler(.cancelled)
                return
            }
            if let data = result?.data {
                self._appData.userAuthToken = data.login.token
                if saveInKeyChain {
                    self._appData.setUserCredentials(credentials: Credentials(username: email, password: password))
                }
                self.applyAuthToGraphQLTransport()
                resultHandler(nil)
                return
            } else {
                if let result = result {
                    if result.hasErrorWithExtension(code: "BAD_USER_INPUT") {
                        resultHandler(.invalidCredentials)
                        return
                    }
                    resultHandler(.serverError)
                    return
                }
                resultHandler(.networkError)
                return
            }
        }
        cancellationToken.setCancellable(cancellable: cancellable)
        _loginCancellationToken = cancellationToken
    }

    public func attemptLoginFromKeyChain(resultHandler: @escaping (_ error: LoginError?) -> Void) {
        guard let credentials = _appData.getUserCredentials() else {
            resultHandler(.invalidCredentials)
            return
        }

        login(email: credentials.username, password: credentials.password, saveInKeyChain: false) {
            loginError in
            if loginError == .invalidCredentials {
                // Delete the invalid credentials from the keychain
                self._appData.removeUserCredentials()
            }

            resultHandler(loginError)
        }
    }
    
    public func signUpWithCode(email: String, code: String, resultHandler: @escaping (_ result: SignUpResult) -> Void) {
        _appData.userAuthToken = nil
        applyAuthToGraphQLTransport()
        _signUpCancellationToken?.cancel()
        let cancellationToken = CancellationToken()
        let cancellable = _apollo.perform(mutation: SignUpWithCodeMutation(email: email, code: code)) { result, _ in
            assert(Thread.isMainThread)
            if cancellationToken.cancelled {
                resultHandler(.cancelled)
                return
            }
            if let data = result?.data {
                if let login = data.signUpWithCode.asSignUpWithCodeLoggedInResponse {
                    self._appData.userAuthToken = login.token
                    self.applyAuthToGraphQLTransport()
                    resultHandler(.success)
                    return
                }
                
                if let actionRequired = data.signUpWithCode.asSignUpWithCodeActionRequiredResponse {
                    switch actionRequired.actionRequired {
                    case .setPassword:
                        resultHandler(.successButMustSetPassword)
                        return
                    case  .login, .__unknown(_):
                        break
                    }
                }
               
                resultHandler(.successButMustLogin)
            } else {
                if let result = result {
                    if result.hasErrorWithExtension(code: "BAD_USER_INPUT") {
                        resultHandler(.invalidCode)
                    } else if result.hasErrorWithExtension(code: "FORBIDDEN") {
                          resultHandler(.forbidden)
                    } else {
                          resultHandler(.serverError)
                    }
                } else {
                    resultHandler(.networkError)
                }
            }
        }
        
        cancellationToken.setCancellable(cancellable: cancellable)
        _signUpCancellationToken = cancellationToken
    }
    
    public func logout(resultHandler: @escaping () -> Void) {
        _apollo.perform(mutation: LogoutMutation()) { _, _ in
            self._appData.userAuthToken = nil
            self._appData.removeUserCredentials()
            self.applyAuthToGraphQLTransport()
            resultHandler()
        }
    }

    public func requestPasswordReset(email: String, resultHandler: @escaping (_ error: RequestError?) ->
        Void) {
        _resetPasswordCancellationToken?.cancel()
        let cancellationToken = CancellationToken()

        let cancellable = _apollo.perform(mutation: RequestPasswordResetMutation(email: email)) { result, _ in
            assert(Thread.isMainThread)
            if cancellationToken.cancelled {
                resultHandler(.cancelled)
                return
            }
            if let data = result?.data, data.requestPasswordReset.success {
                resultHandler(nil)
                return
            } else {
                if result != nil {
                    resultHandler(.serverError)
                    return
                }
                resultHandler(.networkError)
                return
            }
        }
        cancellationToken.setCancellable(cancellable: cancellable)
        _resetPasswordCancellationToken = cancellationToken
    }

    public func applyAuthToURLRequest(urlRequest: inout URLRequest) {
        if let token = _appData.userAuthToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            urlRequest.setValue(nil, forHTTPHeaderField: "Authorization")
        }
    }

    private func applyAuthToGraphQLTransport() {
        if let token = _appData.userAuthToken {
            _alamofireApolloTransport.authorization = "Bearer \(token)"
        } else {
            _alamofireApolloTransport.authorization = nil
        }
    }
}

private class CancellationToken {
    private var _cancelled: Bool = false
    private var _cancellable: Cancellable?
    func setCancellable(cancellable: Cancellable) {
        assert(_cancellable == nil)
        _cancellable = cancellable
    }

    func cancel() {
        _cancelled = true
        _cancellable!.cancel()
    }

    var cancelled: Bool {
        return _cancelled
    }
}
