// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

/**
 A stylised primary-action button.
 */
class PrimaryButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        synchroniseBackgroundColor()
        setTitleColor(UIColor.white, for: UIControl.State.normal)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = frame.size.height / 2
        layer.cornerRadius = radius
    }

    override var isHighlighted: Bool {
        didSet {
            synchroniseBackgroundColor()
        }
    }

    private func synchroniseBackgroundColor() {
        if !isHighlighted {
            // Normal
            backgroundColor = AppColor.appPink
        } else {
            // Pressed
            backgroundColor = UIColor(rgb: 0xFF89AC)
        }
    }
}
