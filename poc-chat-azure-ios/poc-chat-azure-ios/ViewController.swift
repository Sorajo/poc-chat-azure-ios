//
//  ViewController.swift
//  poc-chat-azure-ios
//
//  Created by POC on 15/7/2568 BE.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let chatVC = ChatViewController()
        let nav = UINavigationController(rootViewController: chatVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
}

