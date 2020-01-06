// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

/**
 A wrapper for a DispatchQueue instance that allows one to assert that execution is on the contained queue.
 */
class MarkedDispatchQueue {
    let dispatchQueue: DispatchQueue
    private let dispatchQueueMarker = DispatchSpecificKey<Bool>()

    public init(dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
        dispatchQueue.setSpecific(key: dispatchQueueMarker, value: true)
    }

    /**
     Tests if execution is within the contained DispatchQueue.

     This should ONLY be used for assertions, NEVER for control flow.
     Note that dispatch queues can be nested, thus it is generally not useful to assert the negation of this property.
     */
    public var onDispatchQueue: Bool {
        return DispatchQueue.getSpecific(key: dispatchQueueMarker) ?? false
    }
}
