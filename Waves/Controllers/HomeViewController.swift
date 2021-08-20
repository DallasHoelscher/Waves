//
//  HomeViewController.swift
//  Waves
//
//  Created by Dallas Hoelscher on 5/12/19.
//  Copyright © 2019 Waves. All rights reserved.
//
import SCSDKLoginKit
import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var bitmojiImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noResultsView: UIView!

    var selectedChannel: Channel?
    var userId: String?

    var channels = [Channel]()

    var firstTimeLoggedIn = true

    override func viewDidLoad() {
        super.viewDidLoad()


        FirebaseHandler.shared.channelsFoundCompletion = { channels in
            self.noResultsView.isHidden = !channels.isEmpty

            self.channels = channels
            self.channels = channels.sorted {
                $0.lastUpdated > $1.lastUpdated
            }
            self.tableView.reloadData()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(bitmojiChanged), name: .bitmojiChanged, object: nil)

        let tg = UITapGestureRecognizer(target: self, action: #selector(self.bitmojiTapped))
        bitmojiImageView.isUserInteractionEnabled = true
        bitmojiImageView.addGestureRecognizer(tg)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if SCSDKLoginClient.isUserLoggedIn {
            if firstTimeLoggedIn {
                firstTimeLoggedIn = false

                self.getBitmojiFromStorage()
                FirebaseHandler.shared.getSnapId { snapId in
                    FirebaseHandler.shared.getUserIDAndSetIfNeeded(snapchatId: snapId, completion: { userId in
                        if let userId = userId {
                            self.userId = userId
                            FirebaseHandler.shared.getChannels(forUser: userId)
                            FirebaseHandler.shared.getBlockedUsers(userId: userId)

                            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                appDelegate.registerForNotifications(application: UIApplication.shared)
                                appDelegate.setupNotificationsForFirebase(application: UIApplication.shared)
                            }

                            FirebaseHandler.shared.updateFCMTokenForUser(userId: userId)
                        }
                    })
                }
            }

            self.tableView.reloadData()
        } else {
            self.performSegue(withIdentifier: "goToLogin", sender: nil)
        }
    }

    @objc
    func bitmojiChanged() {
        let url = FirebaseHandler.shared.bitmojiURL
        if !url.isEmpty {
            ImageCache.shared.loadImageUsingCacheWithURLString(url) { image, _ in
                if let image = image {
                    self.bitmojiImageView.image = image
                    self.bitmojiImageView.backgroundColor = .clear
                    self.saveBitmojiToStorage(image: image)
                }
            }
        }
    }

    @objc
    func bitmojiTapped() {
        let optionMenu = UIAlertController(title: nil, message: "\(FirebaseHandler.shared.displayName)", preferredStyle: .actionSheet)
//        let refresh = UIAlertAction(title: "Refresh Bitmoji", style: .default, handler: { _ in
//            print("refresh")
//        })
//        let contactUs = UIAlertAction(title: "Contact Us", style: .default, handler: { _ in
//            print("contact")
//        })

        let logOut = UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            self.removeBitmojiFromStorage()
            SCSDKLoginClient.unlinkAllSessions { _ in
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "goToLogin", sender: nil)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Change `2.0` to the desired number of seconds.
                        //Force crash because of time constraints to fix back end
                        var xx = [Int]()
                        xx[22] = 10
                    }
                }
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            print("Cancelled")
        })
//        optionMenu.addAction(refresh)
//        optionMenu.addAction(contactUs)
        optionMenu.addAction(logOut)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }

    func getBitmojiFromStorage() {
        let defaults = UserDefaults.standard
        if let imgData = defaults.object(forKey: "bitmoji") as? Data {
            if let image = UIImage(data: imgData) {
                self.bitmojiImageView.image = image
                self.bitmojiImageView.backgroundColor = .clear
            }
        }
    }

    func saveBitmojiToStorage(image: UIImage) {
        let defaults = UserDefaults.standard
        let imgData = image.jpegData(compressionQuality: 1.0)
        defaults.set(imgData, forKey: "bitmoji")
    }

    func removeBitmojiFromStorage() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "bitmoji")
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 190
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "homeCell") as? HomeTableCell {
            cell.setup(withChannel: channels[indexPath.row])
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = self.channels[indexPath.row]
        self.selectedChannel = channel
        if let userId = self.userId {
            FirebaseHandler.shared.markChannelAsSeen(channel: channel.id, userId: userId)
        }
        self.performSegue(withIdentifier: "goToMessages", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MessagesViewController {
            vc.channel = self.selectedChannel
            vc.userId = self.userId
        }
    }
}

class HomeTableCell: UITableViewCell {
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var badge: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setup(withChannel channel: Channel) {
        label.text = channel.text
        badge.isHidden = channel.seenByUser
        //Add shadow
//        shadowView.layer.backgroundColor = UIColor.clear.cgColor
//        shadowView.layer.shadowColor = UIColor.black.cgColor
//        shadowView.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
//        shadowView.layer.shadowOpacity = 0.2
//        shadowView.layer.shadowRadius = 4.0
//        shadowView.layer.masksToBounds = false
//
//        container.layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
