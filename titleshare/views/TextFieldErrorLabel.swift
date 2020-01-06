// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

/**
 An error label for text fields.

 The presence (or not) of the label text determines the hidden state of the receiver and the display of an error icon in the rightView of an associated textField.
 */
class TextFieldErrorLabel: ErrorLabel {
    @IBOutlet var textField: UITextField!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        textAlignment = NSTextAlignment.right
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
        textField.rightViewMode = noError ? UITextField.ViewMode.never : UITextField.ViewMode.always
        textField.rightView = noError ? nil : createErrorImageView()
    }

    private func createErrorImageView() -> UIImageView {
        let errorImageView = UIImageView(image: UIImage(named: "views_TextFieldErrorLabel_error"))
        // errorImageView.insets
        return errorImageView
    }
}
