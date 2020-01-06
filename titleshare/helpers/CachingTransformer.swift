// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

/**
 Maps from one type to another, either by generating freshly transformed values or
 by reusing prior transformed values, and caches those mappings for future use.
 */
struct CachingTransformer<S: Hashable, T> {
    private let _transform: (_: S) -> T
    private var _map: [S: T] = [:]

    init(transform: @escaping (_: S) -> T) {
        _transform = transform
    }

    /**
     Transforms a given array, using previous transformations where available
     and caches all returned transformations for future invocations.

     Any previous transformations not returned by this invocation are purged
     (the "limit" part of "limitMap").
     */
    mutating func limitMap(_ items: [S]) -> [T] {
        var newMap: [S: T] = [:]
        let mappedItems: [T] = items.map {
            if let mapped = newMap[$0] {
                return mapped
            }
            let mapped = _map[$0] ?? self._transform($0)
            newMap[$0] = mapped
            return mapped
        }
        _map = newMap
        return mappedItems
    }
}
