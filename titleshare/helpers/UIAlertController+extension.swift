// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

extension UIAlertController {
    func setupPopoverPresentationController(originatingLocation: OriginatingLocation) {
        if let popoverPresentationController = self.popoverPresentationController {
            switch originatingLocation {
            case let .viewRect(view: view, rect: rect):
                popoverPresentationController.sourceView = view
                popoverPresentationController.sourceRect = rect
            }
        }
    }
}
