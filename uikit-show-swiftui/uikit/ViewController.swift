//
//  ViewController.swift
//  uikit
//
//  Created by Yan Cheng Cheok on 08/01/2026.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func tap(_ sender: Any) {
        // Different between show and present:
        // https://stackoverflow.com/questions/26287247/what-are-the-differences-between-segues-show-show-detail-present-modally
        
        let screenB = ScreenB()
        let hostingVC = UIHostingController(rootView: screenB)
        show(hostingVC, sender: nil)
        // OR:
        //navigationController?.pushViewController(hostingVC, animated: true)
        
        /*
        let screenB = ScreenB()
        let hostingVC = UIHostingController(rootView: screenB)
        let nav = UINavigationController(rootViewController: hostingVC)
        //nav.modalPresentationStyle = .pageSheet
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)*/
    }
    
}

