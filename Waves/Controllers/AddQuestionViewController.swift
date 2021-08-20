//
//  AddQuestionViewController.swift
//  Waves
//
//  Created by Dallas Hoelscher on 5/8/19.
//  Copyright © 2019 Waves. All rights reserved.
//

import ColorSlider
import SCSDKCreativeKit
import SCSDKLoginKit
import UIKit

class AddQuestionViewController: UIViewController {
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var shareComponent: UIView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var addToSnapButton: UIButton!
    @IBOutlet weak var addToSnapBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var tapView: UIView!

    var colorSlider: ColorSlider?
    var gradientLayer: CAGradientLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = "Ask me a question"
        textView.autocorrectionType = .no

        colorSlider = ColorSlider(orientation: .horizontal, previewSide: .top)

        colorSlider?.frame = CGRect(x: 16, y: shareView.frame.maxY + 30, width: view.frame.width - 32, height: 12)
        colorSlider?.addTarget(self, action: #selector(changedColor(_:)), for: .valueChanged)
        if let colorSlider = colorSlider {
            view.addSubview(colorSlider)
        }

        gradientLayer = CAGradientLayer()

        gradientLayer?.frame = self.view.bounds

        gradientLayer?.colors = [UIColor.white.cgColor, UIColor.white.cgColor]
        if let gradientLayer = gradientLayer {
            self.shareComponent.layer.insertSublayer(gradientLayer, at: 0)
            //self.shareComponent.layer.lay
        }

        let tg = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.tapView.addGestureRecognizer(tg)
    }

    @objc
    func viewTapped() {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func addToSnapTapped(_ sender: Any) {
        guard let text = textView.text else {
            return
        }
        if text.isEmpty {
            textView.textColor = UIColor.black
        }

        spinner.startAnimating()

        FirebaseHandler.shared.getSnapId { snapId in
            FirebaseHandler.shared.getUserIDAndSetIfNeeded(snapchatId: snapId) { userId in
                guard let userId = userId,
                !userId.isEmpty else {
                    AlertHandler.presentOkayAlert(withTitle: "Error getting your user id. Could be an internet connection issue.", withSubtitle: "", onViewController: self)
                    self.spinner.stopAnimating()
                    return
                }

                DispatchQueue.main.async {
                    print("User ID: \(userId)")
                    self.view.endEditing(true)
                    let image = self.shareView.asImage()
                    let imageToUse = self.createSnapchatImage(image: image)

                    let sticker = SCSDKSnapSticker(stickerImage: imageToUse)

                    FirebaseHandler.shared.createChannel(forUser: userId, text: text, completion: { channelId in
                        guard let channelId = channelId else {
                            AlertHandler.presentOkayAlert(withTitle: "There was an error creating this channel. Could be an internet connection issue.", withSubtitle: "", onViewController: self)
                            self.spinner.stopAnimating()
                            return
                        }
                        let link = "https://wavesapp.fun/send?a=\(channelId)&b=\(userId)&c=\(FirebaseHandler.shared.firstName)"
                        self.view.isUserInteractionEnabled = false
                        let snap = SCSDKNoSnapContent()
                        snap.sticker = sticker
                        snap.attachmentUrl = link
                        let viewState = SCSDKCameraViewState()
                        viewState.cameraPosition = SCSDKCameraPosition.front
                        snap.cameraViewState = viewState

                        let api = SCSDKSnapAPI(content: snap)
                        api.startSnapping { error in
                            DispatchQueue.main.async {
                                self.spinner.stopAnimating()
                                self.view.isUserInteractionEnabled = true
                                self.dismiss(animated: true, completion: nil)
                            }
                            if let error = error {
                                AlertHandler.presentOkayAlert(withTitle: "Snapchat error", withSubtitle: error.localizedDescription, onViewController: self)
                                print("Snap Error: \(error.localizedDescription)")
                            }
                        }
                    })
                }
            }
        }
    }

    func createSnapchatImage(image: UIImage) -> UIImage {
        let baseView = UIView(frame: self.view.frame)
        baseView.backgroundColor = .clear

        let frame = CGRect(x: 8, y: view.frame.height - image.size.height - 150, width: image.size.width, height: image.size.height)

        let imageView = UIImageView(frame: frame)
        imageView.image = image

        baseView.addSubview(imageView)
        return baseView.asImage()
    }

    @objc
    func changedColor(_ slider: ColorSlider) {
        let color = slider.color
        DispatchQueue.main.async {
            if let darker = color.darker(by: 70) {
                self.gradientLayer?.colors = [color.cgColor, darker.cgColor]
            } else {
                self.gradientLayer?.colors = [color.cgColor]
            }
        }
    }

    @objc
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                let height = keyboardSize.height
                self.addToSnapBottomConstraint.constant = height + 32
        }
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                let height = keyboardSize.height
                self.addToSnapBottomConstraint.constant = height + 32
        }
    }
}

extension AddQuestionViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        //if textView.textColor == UIColor.lightGray {
        if textView.text == "Ask me a question" {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        //}
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Ask me a question"
            textView.textColor = UIColor.lightGray
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        let fixedWidth = textView.frame.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: .infinity))

        if newSize.height < 150 {
            textViewHeight.constant = newSize.height
            textView.isScrollEnabled = false
        }

        colorSlider?.frame = CGRect(x: 16, y: shareView.frame.maxY + 30, width: view.frame.width - 32, height: 12)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.addToSnapTapped(self)
            return false
        }
        return true
    }

}
