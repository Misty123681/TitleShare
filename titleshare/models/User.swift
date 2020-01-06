// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

class User {
    let id: String
    private let _metadata: Watchable<UserMetadata>.Source

    init(id: String, metadata: UserMetadata) {
        self.id = id
        _metadata = Watchable.Source(value: metadata)
    }

    init(from memento: Memento) {
        id = memento.id
        _metadata = Watchable.Source(value: memento.metadata)
    }

    public var metadata: Watchable<UserMetadata> {
        return _metadata.watchable
    }
}

extension User {
    struct Memento: Codable {
        let id: String
        let metadata: UserMetadata
    }

    var memento: Memento {
        return Memento(id: id, metadata: _metadata.value)
    }
}
