//
//  LogInViewController.swift
//  Waves
//
//  Created by Dallas Hoelscher on 5/7/19.
//  Copyright © 2019 Waves. All rights reserved.
//

import UIKit
import SCSDKLoginKit

class LogInViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if SCSDKLoginClient.isUserLoggedIn {
            print("Logged in!")
            self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func loginButtonTapped(_ sender: Any) {
        SCSDKLoginClient.login(from: self, completion: { success, error in
            if let error = error {
                print(error.localizedDescription)
                AlertHandler.presentOkayAlert(withTitle: error.localizedDescription, withSubtitle: "", onViewController: self)
                return
            }
            if success {
                //self.fetchSnapUserInfo() //example code
                self.getUserInfo()
            }
        })
    }

    func getUserInfo() {
        let graphQLQuery = "{me{displayName, bitmoji{avatar}, externalId}}"

        let variables = ["page": "bitmoji"]

        SCSDKLoginClient.fetchUserData(withQuery: graphQLQuery, variables: variables, success: { (resources: [AnyHashable: Any]?) in
            guard let resources = resources,
                let data = resources["data"] as? [String: Any],
                let me = data["me"] as? [String: Any] else { return }

            let displayName = me["displayName"] as? String
            var bitmojiAvatarUrl: String?
            if let bitmoji = me["bitmoji"] as? [String: Any] {
                bitmojiAvatarUrl = bitmoji["avatar"] as? String
            }

            print("ME \(me)")
            print("display name \(displayName)")
            print("bitmojiAvatarUrl \(bitmojiAvatarUrl)")
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }

        }, failure: { (error: Error?, isUserLoggedOut: Bool) in
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
}
