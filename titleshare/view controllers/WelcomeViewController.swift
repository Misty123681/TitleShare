// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class WelcomeViewController: UIViewController {
     var webSiteURL:String?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webSiteURL = String(Constants.websiteUrl)
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    // MARK: Actions

    @IBAction func moreInfoTouchUp(_: UIButton) {
       /* guard let url = URL(string: Constants.websiteUrl) else {
            fatalError("Invalid url for more info link")
        }

        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }*/
    }
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        switch segue.identifier {
           
        case "openwbsiteurl":
            guard let destination = segue.destination as? WebViewController else { fatalError("Unexpected destination: \(segue.destination)") }
            guard let url = self.webSiteURL else { fatalError("openWebView expected") }
            destination.urlString = url
             break
         
        default:
            break
        }
    }
}
