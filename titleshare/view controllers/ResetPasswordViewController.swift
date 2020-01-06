// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class ResetPasswordViewController: UIViewController {
    internal var authenticationController: AuthenticationController?
    internal var busyState: BusyState?
    @IBOutlet private var _errorLabel: UILabel!
    @IBOutlet private var _emailTextField: UITextField!
    @IBOutlet private var _emailTextFieldErrorLabel: UILabel!
    @IBOutlet private var _requestPasswordResetButton: UIButton!
    private var _emailValid: Bool = false
    private var _returnKeyPressed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(authenticationController != nil)
        assert(busyState != nil)
        synchroniseValidity()
    }

    @IBAction private func emailTextFieldDidEndOnExit() {
        _returnKeyPressed = true
    }
    
    @IBAction func emailTextFieldEditingChanged() {
        _emailValid = _emailTextField.text?.contains("@") ?? false
        synchroniseValidity()
    }
    
    @IBAction private func emailTextFieldEditingDidEnd() {
        _emailTextField.resignFirstResponder()
        _emailValid = _emailTextField.text?.contains("@") ?? false
        _emailTextFieldErrorLabel.text = _emailValid ? nil : "Invalid email address"
        synchroniseValidity()
        if _returnKeyPressed, _emailValid {
            requestPasswordReset()
        }
        _returnKeyPressed = false
    }

    @IBAction private func requestPasswordResetButtonPrimaryActionTriggered() {
        requestPasswordReset()
    }

    private func synchroniseValidity() {
        _requestPasswordResetButton.isEnabled = _emailValid
    }

    private func requestPasswordReset() {
        if !_emailValid {
            return
        }

        let exitBusyState = busyState!.enter()
        authenticationController!.requestPasswordReset(email: _emailTextField.text ?? "") { requestError in
            exitBusyState()
            if let requestError = requestError {
                switch requestError {
                case .cancelled:
                    // A theoretically impossible case that we can ignore
                    break
                case .networkError:
                    self._errorLabel.text = "A network error occurred, please try again"
                    break
                case .serverError:
                    self._errorLabel.text = "A server error occurred, please try again"
                    break
                }
            } else {
                self._errorLabel.text = ""
                self.performSegue(withIdentifier: "unwindToLoginFromResetPasswordForSuccess", sender: self)
            }
        }
    }
}
