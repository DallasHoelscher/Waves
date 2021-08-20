//
//  MessagesViewController.swift
//  Waves
//
//  Created by Dallas Hoelscher on 5/15/19.
//  Copyright © 2019 Waves. All rights reserved.
//

import UIKit

class MessagesViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var messages = [Message]()
    var userId: String?
    var channel: Channel?

    var selectedMessage: Message?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 43.0;
        tableView.rowHeight = UITableView.automaticDimension

        if let userId = userId,
            !userId.isEmpty,
            let channel = channel {
            FirebaseHandler.shared.getMessagesForChannel(user: userId, channel: channel) { messages in
                print("Found \(messages.count) messages")

                self.messages.removeAll()
                let blockedIP = FirebaseHandler.shared.blockedUsers
                for message in messages {
                    if !blockedIP.contains(message.ip) {
                        self.messages.append(message)
                    } else {
                        print("USER WITH IP \(message.ip) is blocked")
                    }
                }
                self.tableView.reloadData()
            }
        } else {
            return
        }
    }

    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReplyViewController {
            vc.message = self.selectedMessage
            vc.userId = self.userId
            vc.blockUserCompletion = { message in
                DispatchQueue.main.async {
                    for i in 0..<self.messages.count {
                        if self.messages[i].id == message.id {
                            self.messages.remove(at: i)
                            if self.messages.isEmpty {
                                self.dismiss(animated: true, completion: nil)
                                self.tableView.reloadData()
                                return
                            }
                        }
                    }
                }
            }
        }
    }
}

extension MessagesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell") as? MessageCell {
            let m = self.messages[indexPath.row]
            cell.setup(message: m)
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedMessage = self.messages[indexPath.row]
        self.performSegue(withIdentifier: "goToReply", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // handle delete (by removing the data from your array and updating the tableview)
            let message = messages[indexPath.row]
            tableView.beginUpdates()
            messages.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            if let channel = self.channel {
                FirebaseHandler.shared.deleteMessage(channelId: channel.id, messageId: message.id)
            }

            if messages.isEmpty {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

class MessageCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setup(message: Message) {
        titleLabel.text = message.message
        dateLabel.text = getTimeAgoFrom(date: message.timestamp)
    }

    func getTimeAgoFrom(date: Date) -> String {
        let commentDate = date
        //Convert to int because we dont care how precise it is over a second

        let days = Date().days(from: commentDate)
        let hours = Date().hours(from: commentDate)
        let minutes = Date().minutes(from: commentDate)

        var numberToUse = minutes
        var unitToUse = "m"
        if days > 0 {
            numberToUse = days
            unitToUse = "d"
        } else if hours > 0 {
            numberToUse = hours
            unitToUse = "h"
        }

        if unitToUse == "m" && numberToUse == 0 {
            return "Just now"
        }
        return "\(numberToUse)\(unitToUse) ago"
    }
}
