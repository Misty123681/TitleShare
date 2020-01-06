// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import os

enum JoinCodeError {
    case invalidCode
    case forbidden
}

class UserController: NSObject {
    private let _apollo: ApolloClient
    private let _log = OSLog()
    private let _authController: AuthenticationController

    public init(apollo: ApolloClient, authController: AuthenticationController) {
        _apollo = apollo
        _authController = authController
    }

    public func getMe(resultHandler: @escaping (_ resultHandler: RequestResult<User, Void>) -> Void) {
        _apollo.fetchWithAuthRetry(authenticationController: _authController, query: MeQuery()) { result, error in
            if let error = error {
                os_log("Error while attempting graphql request: %@", log: self._log, type: .error, error.localizedDescription)
                resultHandler(RequestResult.networkError(error))
            }

            if let data = result?.data {
                let user = self.mapToUser(from: data.me.fragments.userDetails)
                resultHandler(RequestResult.success(user))
            } else {
                if let result = result {
                    if result.hasErrorWithExtension(code: "UNAUTHENTICATED") {
                        resultHandler(RequestResult.unauthenticated)
                    } else {
                        resultHandler(RequestResult.serverError(nil))
                    }
                } else {
                    resultHandler(RequestResult.networkError(nil))
                }
            }
        }
    }

    public func updateMe(_ firstName: String?, _ lastName: String?, resultHandler: @escaping (_ result: RequestResult<User, Void>) -> Void) {
        _apollo.performWithAuthRetry(authenticationController: _authController, mutation: UpdateMeMutation(firstName: firstName, lastName: lastName)) { result, error in
            if let error = error {
                os_log("Error while attempting graphql request: %@", log: self._log, type: .error, error.localizedDescription)
                resultHandler(RequestResult.networkError(error))
            }

            if let data = result?.data {
                let user = self.mapToUser(from: data.updateMe.fragments.userDetails)
                resultHandler(RequestResult.success(user))
            } else {
                if let result = result {
                    if result.hasErrorWithExtension(code: "UNAUTHENTICATED") {
                        resultHandler(RequestResult.unauthenticated)
                    } else {
                        resultHandler(RequestResult.serverError(nil))
                    }
                } else {
                    resultHandler(RequestResult.networkError(nil))
                }
            }
        }
    }
    
    public func joinCode(code: String, resultHandler: @escaping (_ result: RequestResult<String, JoinCodeError>) -> Void) {
        _apollo.performWithAuthRetry(authenticationController: _authController, mutation: JoinCodeMutation(code: code)) { result, error in
            if let error = error {
                os_log("Error while attempting graphql request: %@", log: self._log, type: .error, error.localizedDescription)
                resultHandler(RequestResult.networkError(error))
            }
            
            if let data = result?.data {
                var nodeName = ""
                if let contentCollection = data.joinCode.asContentCollection {
                    nodeName = contentCollection.name
                }
                resultHandler(RequestResult.success(nodeName))
            } else {
                if let result = result {
                    if result.hasErrorWithExtension(code: "UNAUTHENTICATED") {
                        resultHandler(RequestResult.unauthenticated)
                    } else if result.hasErrorWithExtension(code: "BAD_USER_INPUT") {
                        resultHandler(RequestResult.serverError(.invalidCode))
                    } else if result.hasErrorWithExtension(code: "FORBIDDEN") {
                        resultHandler(RequestResult.serverError(.forbidden))
                    } else {
                        resultHandler(RequestResult.serverError(nil))
                    }
                } else {
                    resultHandler(RequestResult.networkError(nil))
                }
            }
        }
    }

    private func mapToUser(from userDetails: UserDetails) -> User {
        let user = User(
            id: userDetails.id,
            metadata: UserMetadata(
                firstName: userDetails.firstName,
                lastName: userDetails.lastName,
                email: userDetails.email,
                roles: userDetails.roles.map {
                    UserRole(
                        organisationId: $0.organisation?.id ?? "",
                        roleType: self.mapUserRoleType(type: $0.type)
                    )
                }
            )
        )

        return user
    }

    private func mapUserRoleType(type: RoleType) -> UserRoleType? {
        switch type {
        case .consumer:
            return UserRoleType.consumer
        case .orgAdmin:
            return UserRoleType.orgAdmin
        case .sysAdmin:
            return UserRoleType.sysAdmin
        case .__unknown:
            return nil
        }
    }
}
