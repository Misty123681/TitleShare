// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit
import WebKit

class LicensesViewController: UIViewController, WKUIDelegate {
    var webView: WKWebView!

    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let htmlPath = Bundle.main.path(forResource: "licenses", ofType: "html") else {
            fatalError("Could not find licenses.html file")
        }

        var html: String = ""
        do {
            html = try String(contentsOfFile: htmlPath, encoding: String.Encoding.utf8)
        } catch {
            fatalError("Could not load licenses.html file")
        }

        webView.loadHTMLString(html, baseURL: URL(string: ""))
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}
