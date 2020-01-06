// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

// UIAlertController presentation requires knowledge of the
// anchor of presentation.
// This enum encapsulates that info, allowing it to be opaquely
// passed through the view model(s).
enum OriginatingLocation {
    case viewRect(view: UIView, rect: CGRect)
    // add bar button item when needed
}
