// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

enum RequestResult<Data, ServerError> {
    case success(Data)
    case cancelled
    case networkError(Error?)
    case serverError(ServerError?)
    case unauthenticated
}
