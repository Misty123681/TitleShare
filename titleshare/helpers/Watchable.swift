// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

/**
 A wrapper type for watchable values.

 The mutation and immutable parts are separated to aid in keeping implementation details private.
 The lifetime of the `Watchable` can outlive the owning `Watchable.Source`.
 The `Watchable` owns the data, thus making it accessible beyond the lifetime of the `Watchable.Source`.
 The watchers are stored within the `Watchable`:- they are not needed beyond the lifetime of the `Watchable.Source`.
 */
public final class Watchable<T> {
    typealias WatchHandler = (T) -> Void

    public fileprivate(set) var value: T
    fileprivate weak var source: Source?

    init(value: T) {
        self.value = value
    }

    /**
     Watches for changes to the value.

     Passing true for invokeNow will cause the watchHandler to be invoked before this method returns.
     The watch will remain active for as long as the returned Resource exists.
     Care must be taken to ensure the watchHandler doesn't (directly or indirectly) strongly reference
     the Watchable Source.
     */
    func watch(invokeNow: Bool, watchHandler: @escaping WatchHandler) -> Resource {
        let resource = source?.watch(watchHandler: watchHandler) ?? Resource()
        if invokeNow {
            watchHandler(value)
        }
        return resource
    }

    final class Source {
        private class Watcher {
            let watchHandler: WatchHandler
            init(watchHandler: @escaping WatchHandler) {
                self.watchHandler = watchHandler
            }
        }

        public let watchable: Watchable
        private var _watchers: [Watcher] = Array<Watcher>()

        init(value: T) {
            watchable = Watchable(value: value)
            watchable.source = self
        }

        public var value: T {
            get {
                return watchable.value
            }
            set(newValue) {
                watchable.value = newValue
                for watcher in _watchers {
                    watcher.watchHandler(newValue)
                }
            }
        }

        fileprivate func watch(watchHandler: @escaping WatchHandler) -> Resource {
            let watcher = Watcher(watchHandler: watchHandler)
            let resource = Resource()
            resource.uponRelease { [weak self] in
                guard let self = self else { return }
                guard let watcherIndex = self._watchers.lastIndex(where: { $0 === watcher }) else { return }
                self._watchers.remove(at: watcherIndex)
            }
            _watchers.append(watcher)
            return resource
        }
    }
}
