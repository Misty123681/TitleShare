// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit
import SafariServices
import WebKit
class WebViewController: UIViewController, WKUIDelegate,WKNavigationDelegate {
    var urlString = ""
    var webView: WKWebView!
    var actInd: UIActivityIndicatorView = UIActivityIndicatorView()


    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        //self.view = self.webView
        self.webView.frame = self.view.frame
        self.view.addSubview(self.webView)
        if let url = URL(string: self.urlString) {
            print("URL - \(self.urlString)")
            let request = URLRequest(url: url)
           self.webView.load( request)
        }
        
        
        self.actInd.style = UIActivityIndicatorView.Style.gray
        self.actInd.center = self.view.center
        self.view.addSubview(actInd)
        self.actInd.isHidden = false
        self.actInd.hidesWhenStopped = true
        self.actInd.startAnimating()
        self.actInd.bringSubviewToFront(self.webView)
        self.webView.sendSubviewToBack(self.actInd)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
     
 override func viewWillAppear(_: Bool) {
     navigationController?.setNavigationBarHidden(false, animated: true)
 }
  
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)
    {
        print(#function)
        self.actInd.startAnimating()
        
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      print("finish to load")
         print(#function)
        self.actInd.stopAnimating()
  }

    private func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
          print(error.localizedDescription)
        self.actInd.stopAnimating()
      }
}
