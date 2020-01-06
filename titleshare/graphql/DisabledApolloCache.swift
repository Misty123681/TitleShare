// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation

/**
 A dummy instance to inhibit caching within Apollo.
 */
public final class DisabledApolloCache: NormalizedCache {
    public func loadRecords(forKeys keys: [CacheKey]) -> Promise<[Record?]> {
        return Promise(fulfilled: Array(repeating: nil, count: keys.count))
    }

    public func merge(records: RecordSet) -> Promise<Set<CacheKey>> {
        var dummyRecords = RecordSet()
        return Promise(fulfilled: dummyRecords.merge(records: records))
    }

    public func clear() -> Promise<Void> {
        return Promise(fulfilled: ())
    }
}
