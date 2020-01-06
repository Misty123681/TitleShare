// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

/**
 Represents and controls the lifetime of an arbitrary resource, with configurable cleanup handlers which are invoked upon deinitialisation.
 */
class Resource {
    private var _releaseTasks: [() -> Void]? = []
    private lazy var _resources: [Resource] = []

    deinit {
        let reversedReleaseTasks = _releaseTasks!.reversed()
        _releaseTasks = nil
        for releaseTask in reversedReleaseTasks {
            releaseTask()
        }
    }

    /**
     Adds a release task to this resource which will be invoked upon destruction of this resource instance.
     */
    func uponRelease(fn: @escaping () -> Void) {
        guard _releaseTasks != nil else { fn(); return }
        _releaseTasks!.append(fn)
    }

    /**
     Adds a resource to this resource which will be released upon destruction of this resource instance.
     */
    func aggregate(resource: Resource) {
        _resources.append(resource)
    }
}
