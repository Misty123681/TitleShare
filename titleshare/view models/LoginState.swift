// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class LoginState {
    public static func requestLogin() {
        guard let appDel = UIApplication.shared.delegate as? AppDelegate else { return }
        let rootController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "LoginNavigationController")
        appDel.window?.rootViewController = rootController
    }

    public static func requestWelcomeScene() {
        guard let appDel = UIApplication.shared.delegate as? AppDelegate else { return }
        let rootController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "WelcomeNavigationController")
        appDel.window?.rootViewController = rootController
    }
}
