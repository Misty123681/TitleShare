// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

/**
 An error label.

 The presence (or not) of the label text determines the hidden state of the receiver.
 */
class ErrorLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        numberOfLines = 0
        textColor = UIColor(red: 0xC4 / 255.0, green: 0x06 / 255.0, blue: 0x06 / 255.0, alpha: 1)
        font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption1)
        if #available(iOS 10, *) {
            adjustsFontForContentSizeCategory = true
        }
    }

    override var text: String? {
        get {
            return super.text
        }
        set(value) {
            super.text = value
            synchroniseState()
        }
    }

    private func synchroniseState() {
        let noError = super.text?.isEmpty ?? true
        isHidden = noError
    }
}
