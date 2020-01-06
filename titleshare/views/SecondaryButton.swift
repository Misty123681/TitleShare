// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

/**
 A stylised secondary-action button.
 */
class SecondaryButton: UIButton {
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
        super.setTitleColor(AppColor.appPink, for: UIControl.State.normal)
        layer.borderColor = AppColor.appPink.cgColor
        layer.borderWidth = 1
    }

    override func setTitleColor(_: UIColor?, for _: UIControl.State) {
        // intentionally do nothing
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
            backgroundColor = UIColor.white
        } else {
            // Pressed
            backgroundColor = UIColor(rgb: 0xFFEAF1)
        }
    }
}
