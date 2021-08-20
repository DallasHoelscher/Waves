//
//  ReplyViewController.swift
//  Waves
//
//  Created by Dallas Hoelscher on 5/15/19.
//  Copyright © 2019 Waves. All rights reserved.
//

import SCSDKCreativeKit
import UIKit

class ReplyViewController: UIViewController {
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var shareMessageLabel: UILabel!
    @IBOutlet weak var shareResponseLabel: UILabel!
    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var tapView: UIView!

    var userId: String?
    var message: Message?

    var blockUserCompletion: ((Message) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.autocorrectionType = .no
        textView.becomeFirstResponder()
        titleLabel.text = message?.message
        shareMessageLabel.text = message?.message
        let tg = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.tapView.addGestureRecognizer(tg)
    }

    @IBAction func replyTapped(_ sender: Any) {
        share()
    }

    @IBAction func blockUserTapped(_ sender: Any) {
        AlertHandler.presentDeleteAlert(onViewController: self, withTitle: "Are you sure you want to block this user?") {
            print("Block user with ip \(self.message?.ip ?? "nil")")
            if let userId = self.userId,
                let message = self.message {
                FirebaseHandler.shared.blockUser(myUserId: userId, blockedUsersIP: message.ip)
                self.blockUserCompletion?(message)
            } else {
                AlertHandler.presentOkayAlert(withTitle: "There was an error blocking user. Please conact support with this error code.", withSubtitle: "\(self.message?.id ?? "M_ID_NIL")", onViewController: self)
            }
        }
    }

    @objc
    func viewTapped() {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }

    func share() {
        if textView.text.isEmpty {
            AlertHandler.presentOkayAlert(withTitle: "Enter a message first", withSubtitle: "", onViewController: self)
            return
        }

        let image = self.shareView.asImage()
        let imageToUse = self.createSnapchatImage(image: image)

        let sticker = SCSDKSnapSticker(stickerImage: imageToUse)
        self.view.isUserInteractionEnabled = false
        let snap = SCSDKNoSnapContent()
        snap.sticker = sticker
        snap.attachmentUrl = "https://wavesapp.fun/home"
        let viewState = SCSDKCameraViewState()
        viewState.cameraPosition = SCSDKCameraPosition.front
        snap.cameraViewState = viewState

        let api = SCSDKSnapAPI(content: snap)
        api.startSnapping { error in
            DispatchQueue.main.async {
                //self.spinner.stopAnimating()
                self.view.isUserInteractionEnabled = true
                self.dismiss(animated: true, completion: nil)
            }
            if let error = error {
                AlertHandler.presentOkayAlert(withTitle: "Snapchat error", withSubtitle: error.localizedDescription, onViewController: self)
                print("Snap Error: \(error.localizedDescription)")
            }
        }
    }

    func createSnapchatImage(image: UIImage) -> UIImage {
        let baseView = UIView(frame: self.view.frame)
        baseView.backgroundColor = .clear

        let frame = CGRect(x: 8, y: view.frame.height - image.size.height - 140, width: image.size.width, height: image.size.height)

        let imageView = UIImageView(frame: frame)
        imageView.image = image

        baseView.addSubview(imageView)
        return baseView.asImage()
    }
}

extension ReplyViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let fixedWidth = textView.frame.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: .infinity))

        if newSize.height < 150 {
            textViewHeight.constant = newSize.height
            textView.isScrollEnabled = false
        }

        shareResponseLabel.text = textView.text
    }
}
