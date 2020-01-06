// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation
import UIKit

typealias ExitBusyState = () -> Void

/**
 Provides safe multi-access control of a global busy indicator which covers the window and acts as a first responder.

 This class is intended to be a singleton which is injected where needed.
 */
class BusyState {
    private var _busyCount: Int = 0
    private var screenLock: ScreenLock?

    /**
     Displays the busy indicator for at least as long as until the returned idempotent closure is invoked.

     The busy indicator is shown while there is at least one unexited enter invocation.
     */
    func enter() -> ExitBusyState {
        assert(Thread.isMainThread)
        if _busyCount == 0 {
            transitionToBusy()
        }
        _busyCount += 1
        var exited = false
        return {
            assert(Thread.isMainThread)
            if exited {
                return
            }
            exited = true
            self._busyCount -= 1
            if self._busyCount == 0 {
                self.transitionToNotBusy()
            }
        }
    }

    private func transitionToBusy() {
        let window = UIApplication.shared.keyWindow
        if screenLock == nil {
            screenLock = ScreenLock(frame: CGRect(origin: CGPoint(x: 10, y: 10), size: CGSize(width: 200, height: 120)))
            window?.addSubview(screenLock!)
            screenLock!.coverParent()
        }

        window?.bringSubviewToFront(screenLock!)
        screenLock!.lock()
    }

    private func transitionToNotBusy() {
        if screenLock != nil {
            DispatchQueue.main.async {
                self.screenLock?.unlock()
            }
        }
    }
}
