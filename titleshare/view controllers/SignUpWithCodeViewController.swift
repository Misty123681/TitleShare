// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class SignUpWithCodeViewController: UIViewController {
    internal var authenticationController: AuthenticationController?
    internal var busyState: BusyState?
    @IBOutlet var _errorLabel: UILabel!
    @IBOutlet var _emailTextField: UITextField!
    @IBOutlet var _emailTextFieldErrorLabel: UILabel!
    @IBOutlet var _codeTextField: UITextField!
    @IBOutlet var _signUpButton: UIButton!
    
    private var _emailValid: Bool = false
    private var _returnKeyPressed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(authenticationController != nil)
        assert(busyState != nil)
        synchroniseValidity()
    }
    
    override func viewWillAppear(_: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @IBAction private func emailTextFieldDidEndOnExit() {
        _returnKeyPressed = true
    }
    
    @IBAction private func emailTextFieldEditingDidEnd() {
        _emailTextField.resignFirstResponder()
        _emailValid = _emailTextField.text?.contains("@") ?? false
        _emailTextFieldErrorLabel.text = _emailValid ? nil : "Invalid email address"
        synchroniseValidity()
        if _returnKeyPressed, _emailValid {
            _codeTextField.becomeFirstResponder()
        }
        _returnKeyPressed = false
    }
    
    @IBAction private func signUpButtonPrimaryActionTriggered() {
        signUp();
    }
    
    @IBAction private func codeTextFieldDidEndOnExit() {
        signUp();
    }
    
    @IBAction func termsOfServiceButtonPrimaryActionTriggered() {
        guard let url = URL(string: Constants.termsAndConditionsUrl) else {
            fatalError("Invalid url for \(Constants.termsAndConditionsUrl)")
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func privacyPolicyPrimaryActionTriggered() {
        guard let url = URL(string: Constants.privacyUrl) else {
            fatalError("Invalid url for \(Constants.privacyUrl)")
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction private func helpButtonPrimaryActionTriggered() {
        let emailAddress = URL(string: "mailto:\(Constants.supportEmail)")!
        if UIApplication.shared.canOpenURL(emailAddress) {
            UIApplication.shared.open(emailAddress, options: [:], completionHandler: nil)
        } else {
            guard let url = URL(string: Constants.faqUrl) else {
                fatalError("Invalid url for \(Constants.faqUrl)")
            }
            
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func synchroniseValidity() {
        _signUpButton.isEnabled = _emailValid
    }

    private func signUp() {
        if !_emailValid {
            return
        }
        let exitBusyState = busyState!.enter()
        authenticationController!.signUpWithCode(email: _emailTextField.text ?? "", code: _codeTextField.text ?? "") { result in
            exitBusyState()
            
            switch result {
            case .cancelled:
                // A theoretically impossible case that we can ignore
                ()
            case .invalidCode:
                self._errorLabel.text = "Invalid code"
            case .forbidden:
                 self._errorLabel.text = "Forbidden"
            case .networkError:
                self._errorLabel.text = "A network error occurred, please try again"
            case .serverError:
                self._errorLabel.text = "A server error occurred, please try again"
            case .successButMustSetPassword:
                self._errorLabel.text = "You must set a password for your account. Please check your email for instructions on setting your titleShare password, then return here to login and access these titles."
            case .successButMustLogin:
                self._errorLabel.text = nil
                self.performSegue(withIdentifier: "mustLogin", sender: self)
            case .success:
                self._errorLabel.text = nil
                self.performSegue(withIdentifier: "signUpSuccess", sender: self)
            }
        }
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let loginController = segue.destination as? LoginViewController {
            let message = "We see you already have an account. \nPlease login to access these titles"
            loginController.prePopulate(initialMessage: message, email: _emailTextField.text ?? "")
            return
        }
        
        if let tabBarController = segue.destination as? UITabBarController,
            let tabBarViewControllers = tabBarController.viewControllers,
            let navController = tabBarViewControllers[0] as? UINavigationController,
            let audiobooksController = navController.viewControllers[0] as? AudiobooksCollectionViewController {
                audiobooksController.viewDidLoadAction = { [weak audiobooksController] in
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Code Accepted", message: "You will be sent an email to verify your account", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                        audiobooksController?.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        
     }
}
