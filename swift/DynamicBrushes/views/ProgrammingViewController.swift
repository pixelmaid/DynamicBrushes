//
//  ProgrammingViewController.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 11/20/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation

import UIKit
import WebKit
import SwiftyJSON

class ProgrammingViewController:UIViewController,  WKUIDelegate {
    
    var webView:WKWebView!
    var returnButton:UIButton!
    var programmingEvent = Event<(String,JSON?)>();
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
  
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
        returnButton = UIButton(frame: CGRect(x:10,y:10,width:100,height:100));
        returnButton.setTitle("return", for: UIControlState.normal)
        view.addSubview(returnButton)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        returnButton!.addTarget(self, action: #selector(ProgrammingViewController.returnPressed), for: .touchUpInside)
        
        
        let myURL = URL(string: "https://web.media.mit.edu/~jacobsj/dynamicbrushes")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        //print("view",self.view);
    }
    
    
    @objc func returnPressed(){
        self.programmingEvent.raise(data: ("RETURN_TO_MAIN",nil))
    }
    
}
