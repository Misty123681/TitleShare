// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

/**
 A UITextField subclass that offers padding for the right view.

 UITextField offers no built-in padding for the right view, which looks bad. This class fixes it.
 */
class TextFieldWithPaddedRightView: UITextField {
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let originalRect = super.rightViewRect(forBounds: bounds)
        return originalRect.offsetBy(dx: -8.0, dy: 0)
    }
}
