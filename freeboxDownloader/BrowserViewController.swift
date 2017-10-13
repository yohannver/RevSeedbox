//
//  BrowserViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 20/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit
import WebKit

class BrowserViewController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView!
    
    //let url = "http://www.t411.li/"
    let url = "https://google.fr"
    
    var _httpRequestFreebox:HttpRequestFreebox = HttpRequestFreebox()
    
    let USER_DEFAULTS = UserDefaults.standard
    
    var fileManager = FileManager()
    var tmpDir = NSTemporaryDirectory()
    let fileName = "sample.txt"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mySelector: Selector = #selector(BrowserViewController.clickClose)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "delete"), style: UIBarButtonItemStyle.done, target: self, action: mySelector)

        /*let url = URL(string:"http://www.apple.com/")
        let req = URLRequest(url:url!)
        self.webView!.load(req)*/
        
        _httpRequestFreebox.app_token = USER_DEFAULTS.string(forKey: HttpRequestFreebox.APP_TOKEN)
        
        //Récupération de l'IP de la freeboxserver dans les userdefaults
        _httpRequestFreebox.ipServer = USER_DEFAULTS.string(forKey: HttpRequestFreebox.IP_FREEBOXSERVER)
        //Récupération le port de la freeboxserver dans les userdefaults
        _httpRequestFreebox.portServer = USER_DEFAULTS.integer(forKey: HttpRequestFreebox.REMOTE_ACCESS_PORT)
        
        _httpRequestFreebox.getLocalURLOrIP()
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        
        webView.navigationDelegate = self
        
        webView.allowsBackForwardNavigationGestures = true
        
        view.addSubview(webView)
        
        webViewLoadUrl(url: url)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.closeBrowser),name:NSNotification.Name(rawValue: "addDownloadSuccess"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func clickClose() {
        dismiss(animated: true, completion: nil)
    }
    
    func webViewLoadUrl(url: String) {
        if let url = URL(string: url) {
            let req = URLRequest(url: url)
            
            webView.load(req)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        let request = navigationAction.request
        let url = request.url
        let absoluteString = url!.absoluteString
        print("URL : \(absoluteString)")
        
        if absoluteString.contains("download/?id=") {
            
            
            //The URL to Save
            let urlDownload = URL(string: absoluteString)
            //Create a URL request
            let urlRequest = URLRequest(url: urlDownload!)
            
            do {
                //get the data
                let theData = try NSURLConnection.sendSynchronousRequest(urlRequest, returning: nil)
                
                var docURL = (fileManager.urls(for: .documentDirectory, in: .userDomainMask)).last
                
                //Get the local docs directory and append your local filename.
                docURL = NSURL(fileURLWithPath: docURL!.absoluteString).appendingPathComponent("fichier.exe")
                
                var docUrlString = docURL!.absoluteString
                
                //Lastly, write your file to the disk.
                try theData.write(to: docURL!)
                
                self._httpRequestFreebox.addDownloadByFileUploading(fileUrl: docURL!)
            } catch let erreur as NSError {
                print("Failed to create file")
                print("Erreur : \(erreur)")
            }
            
            let files = fileManager.enumerator(atPath: NSHomeDirectory())
            while let file = files?.nextObject() {
                print(file)
            }
            
        } else if absoluteString.contains(".exe") || absoluteString.contains(".mp3") || absoluteString.contains(".pdf") {
            self._httpRequestFreebox.addSingleDownloadByURL(url: absoluteString)
        }
        
        decisionHandler(.allow)
    }
    
    func closeBrowser() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        dismiss(animated: true, completion: nil)
    }

}
