// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

class UserState {
    private let _userController: UserController
    private let _user: Watchable<User?>.Source

    init(from memento: Memento?, userController: UserController) {
        _userController = userController

        if let memento = memento, let user = memento.user {
            _user = Watchable.Source(value: User(from: user))
        } else {
            _user = Watchable.Source(value: nil)
        }
    }

    public var user: Watchable<User?> {
        return _user.watchable
    }

    public func fetchCurrentUser(resultHandler: @escaping (_ resultHandler: RequestResult<User, Void>) -> Void) {
        _userController.getMe { result in
            if case let .success(user) = result {
                self._user.value = user
            }

            resultHandler(result)
        }
    }

    public func update(firstname: String?, lastname: String?, resultHandler: @escaping (_ result: RequestResult<User, Void>) -> Void) {
        _userController.updateMe(firstname, lastname) { result in
            if case let .success(user) = result {
                self._user.value = user
            }

            resultHandler(result)
        }
    }
    
    public func joinCode(code: String, resultHandler: @escaping (_ result: RequestResult<String, JoinCodeError>) -> Void) {
        _userController.joinCode(code: code, resultHandler: resultHandler)
    }
}

extension UserState {
    struct Memento: Codable {
        let user: User.Memento?
    }

    var memento: Memento {
        return Memento(user: user.value?.memento)
    }
}
