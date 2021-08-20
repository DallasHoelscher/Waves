//
//  AlertHandler.swift
//  Waves
//
//  Created by Dallas Hoelscher on 5/11/19.
//  Copyright © 2019 Waves. All rights reserved.
//
import Foundation
import UIKit

class AlertHandler {

    class func presentDeleteAlert(onViewController vc: UIViewController, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        alert.addAction(UIAlertAction(title: "Remove Friend", style: .destructive, handler: { _ in
            completion()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
        }))
        vc.present(alert, animated: true, completion: nil)
    }

    class func presentDeleteAlert(onViewController vc: UIViewController, withTitle title: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            completion()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
        }))
        vc.present(alert, animated: true, completion: nil)
    }

    class func presentOkayAlert(withTitle title: String, withSubtitle subtitle: String, onViewController vc: UIViewController) {
        presentOkayAlert(withTitle: title, withSubtitle: subtitle, onViewController: vc) {
            //Do nothing
        }
    }

    class func presentOkayAlert(withTitle title: String, withSubtitle subtitle: String, onViewController vc: UIViewController, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            completion()
        }))
        vc.present(alert, animated: true, completion: nil)
    }
}
