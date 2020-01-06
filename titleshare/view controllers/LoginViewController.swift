// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class LoginViewController: UIViewController {
    internal var authenticationController: AuthenticationController?
    internal var busyState: BusyState?
   
    @IBOutlet private var _initMessageLabel: UILabel!
    @IBOutlet private var _errorLabel: UILabel!
    @IBOutlet private var _passwordTextField: UITextField!
    @IBOutlet private var _emailTextField: UITextField!
    @IBOutlet private var _emailTextFieldErrorLabel: UILabel!
    @IBOutlet private var _loginButton: UIButton!
    private var _emailValid: Bool = false
    private var _returnKeyPressed = false
    private var _initMessage: String = ""
    private var _initEmail: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(authenticationController != nil)
        assert(busyState != nil)
        _initMessageLabel.text = _initMessage
        _emailTextField.text = _initEmail
        synchroniseValidity(displayError: false)
        
        self._emailTextField.text = "ravindra.sk@flatworldsolutions.com"
        self._passwordTextField.text = "Ravi@1234"
    }
    
    func prePopulate(initialMessage: String, email: String) {
        _initMessage = initialMessage
        _initEmail = email
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    @IBAction private func emailTextFieldDidEndOnExit() {
        _returnKeyPressed = true
    }

    @IBAction private func emailTextFieldEditingDidEnd() {
        _emailTextField.resignFirstResponder()
        synchroniseValidity()
        if _returnKeyPressed, _emailValid {
            _passwordTextField.becomeFirstResponder()
        }
        _returnKeyPressed = false
    }

    @IBAction private func passwordTextFieldDidEndOnExit() {
        login()
    }

    @IBAction private func loginButtonPrimaryActionTriggered() {
        login()
    }

    @IBAction func termsOfServiceButtonPrimaryActionTriggered() {
//        guard let url = URL(string: Constants.termsAndConditionsUrl) else {
//            fatalError("Invalid url for \(Constants.termsAndConditionsUrl)")
//        }
//        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        self.showTermsCondition(urlString: Constants.termsAndConditionsUrl)
    }

    @IBAction func privacyPolicyPrimaryActionTriggered() {
//        guard let url = URL(string: Constants.privacyUrl) else {
//            fatalError("Invalid url for \(Constants.privacyUrl)")
//        }
//        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        self.showTermsCondition(urlString: Constants.privacyUrl)
    }

    @IBAction private func helpButtonPrimaryActionTriggered() {
        // MARK: (As with #pragma, marks followed by a single dash (-) are preceded with a horizontal divider)
        // TODO: will Have to implement help section in the login view
        // FIXME: Will do it by today evening
        let emailAddress = URL(string: "mailto:\(Constants.supportEmail)")!
        if UIApplication.shared.canOpenURL(emailAddress) {
            UIApplication.shared.open(emailAddress, options: [:], completionHandler: nil)
        } else {
//            guard let url = URL(string: Constants.faqUrl) else {
//                fatalError("Invalid url for \(Constants.faqUrl)")
//            }
//
//            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            self.showTermsCondition(urlString: Constants.faqUrl)
        }
    }

    @IBAction func unwindToLoginFromResetPasswordForSuccess(segue _: UIStoryboardSegue) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Password Reset", message: "An email with password reset instructions will be sent to your account.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func synchroniseValidity(displayError: Bool = true) {
        _emailValid = _emailTextField.text?.contains("@") ?? false
        _emailTextFieldErrorLabel.text = _emailValid || !displayError ? nil : "Invalid email address"
        _loginButton.isEnabled = _emailValid
    }

    private func login() {
        if !_emailValid {
            return
        }
        let exitBusyState = busyState!.enter()
        authenticationController!.login(email: _emailTextField.text ?? "", password: _passwordTextField.text ?? "", saveInKeyChain: true) { loginError in
            exitBusyState()
            if let loginError = loginError {
                switch loginError {
                case .cancelled:
                    // A theoretically impossible case that we can ignore
                    ()
                case .invalidCredentials:
                    self._errorLabel.text = "Invalid email or password"
                case .networkError:
                    self._errorLabel.text = "A network error occurred, please try again"
                case .serverError:
                    self._errorLabel.text = "A server error occurred, please try again"
                }
            } else {
                self._errorLabel.text = nil
                self.performSegue(withIdentifier: "loginSuccess", sender: self)
            }
        }
    }
    
     //MARK: -  showTermsCondition Method for open URl in the safari view controller inside the app.
     
    func showTermsCondition(urlString:String){
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
           controller.urlString = urlString
            self.navigationController?.pushViewController(controller, animated: false)
       }
}
