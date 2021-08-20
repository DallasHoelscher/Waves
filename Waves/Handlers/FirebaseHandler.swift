//
//  FirebaseHandler.swift
//  Waves
//
//  Created by Dallas Hoelscher on 5/11/19.
//  Copyright © 2019 Waves. All rights reserved.
//

import Firebase
import FirebaseFirestore
import Foundation
import SCSDKLoginKit

private let db = Firestore.firestore()

class FirebaseHandler {
    static let shared = FirebaseHandler()
    var currentFCMToken = ""
    var channelsFoundCompletion: (([Channel]) -> Void)?

    //The users UUID
    var userID = ""
    ///The users snapchat ID
    var currentlyLoggedInUser = ""
    var bitmojiURL = "" {
        didSet {
            NotificationCenter.default.post(name: .bitmojiChanged, object: nil)
        }
    }
    var firstName = ""
    var displayName = ""
    var blockedUsers = [String]()
    private init() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        // Enable offline data persistence
        let db = Firestore.firestore()
        db.settings = settings
    }

    func generateCollectionID() -> String {
        return db.collection("testRef").document().documentID
    }

    func getSnapId(completion: @escaping (String) -> Void) {
        if !currentlyLoggedInUser.isEmpty {
            completion(currentlyLoggedInUser)
            return
        }

        if SCSDKLoginClient.isUserLoggedIn {
            let graphQLQuery = "{me{displayName, bitmoji{avatar}, externalId}}"

            let variables = ["page": "bitmoji"]

            SCSDKLoginClient.fetchUserData(withQuery: graphQLQuery, variables: variables, success: { (resources: [AnyHashable: Any]?) in
                guard let resources = resources,
                    let data = resources["data"] as? [String: Any],
                    let me = data["me"] as? [String: Any],
                    let externalID = me["externalId"] as? String
                    else { return }

                let displayName = me["displayName"] as? String ?? ""
                self.firstName = String(displayName.split(separator: " ").first ?? "")
                self.displayName = displayName

                if let bitmoji = me["bitmoji"] as? [String: Any],
                    let url = bitmoji["avatar"] as? String {
                    self.bitmojiURL = url
                }
                print("ME \(me)")
                print("display name \(self.firstName)")
                print("bitmojiAvatarUrl \(self.bitmojiURL)")
                completion(externalID)
            }, failure: { (error: Error?, isUserLoggedOut: Bool) in
                // handle error
                print("\(error?.localizedDescription ?? "nil") user is logged out \(isUserLoggedOut) could not fetch users data")
            })
        }
    }

    func getUserIDAndSetIfNeeded(snapchatId: String, completion: @escaping (String?) -> Void) {
        let snapID = snapchatId.replacingOccurrences(of: "/", with: "_")
        print("snapID became \(snapID)")
        if snapID == currentlyLoggedInUser {
            completion(userID)
            return
        } else {
            currentlyLoggedInUser = snapID
        }

        if snapID.isEmpty {
            completion(nil)
            return
        }
        let docRef = db.collection("userIds").document(snapID)

        docRef.getDocument { document, error in
            if let error = error {
                print("\(error.localizedDescription) ?? nil error")
                completion(nil)
                return
            }

            if let document = document, document.exists {
                if let data = document.data() {
                    if let userId = data["userId"] as? String {
                        self.userID = userId
                        completion(userId)
                        return
                    } else {
                        completion(nil)
                        return
                    }
                } else {
                    completion(nil)
                    return
                }
            } else {
                //Generate random id, save it, and then return
                let uuid = UUID().uuidString
                docRef.setData(["userId": uuid], completion: { error in
                    if let error = error {
                        print("Error setting userId \(error.localizedDescription)")
                        completion(nil)
                        return
                    } else {
                        self.userID = uuid
                        completion(uuid)
                        return
                    }
                })
            }
        }
    }

    ///Completion passes the channel id or null if there was a problem
    func createChannel(forUser userId: String, text: String, completion: @escaping (String?) -> Void) {
        let data: [String: Any] = ["lastUpdated": FieldValue.serverTimestamp(), "text": text]
        let docRef = db.collection("channels/\(userId)/channels").document()

        docRef.setData(data, completion: { error in
            if let error = error {
                print(error.localizedDescription)
                completion(nil)
                return
            } else {
                completion(docRef.documentID)
                return
            }
        })
    }

    func getMessagesForChannel(user userId: String, channel: Channel, completion: @escaping ([Message]) -> Void) {
        db.collection("messages/\(channel.id)/message")
            .order(by: "timestamp", descending: true)
            .limit(to: 30)
            .whereField("shouldShow", isEqualTo: true)
            .getDocuments { snapshot, error in
                print("Path is messages/\(channel.id)/message")
                guard let documents = snapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "nil")")
                    return
                }

                var messages = [Message]()
                for document in documents {
                    if let timestamp = document.get("timestamp") as? Timestamp,
                        let text = document.get("message") as? String {
                        let date = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))

                        let ip = document.get("ipAddress") as? String ?? "Error finding ip address"
                        let m = Message(id: document.documentID, message: text, timestamp: date, ip: ip)
                        messages.append(m)
                    }
                }
                completion(messages)
            }
        }

    func deleteMessage(channelId: String, messageId: String) {
        db.collection("messages/\(channelId)/message").document(messageId).updateData(["shouldShow" : false]) { error in
            if let error = error {
                print("deleteMessage error: \(error.localizedDescription)")
                return
            }
            print("Deleted message \(messageId) in channel \(channelId)")
        }
    }

    func blockUser(myUserId userId: String, blockedUsersIP ip: String) {
        if userId.isEmpty || ip.isEmpty {
            return
        }

        db.collection("blockedUsers").document(userId).setData([ip: true], merge: true)
    }

    func getBlockedUsers(userId: String) {
        if userId.isEmpty {
            return
        }

        db.collection("blockedUsers").document(userId).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("getBlockedUsers -> \(error.localizedDescription)")
                return
            }
            guard let document = documentSnapshot else {
                print("Error fetching getBlockedUsers document: \(error!)")
                return
            }
            guard let data = document.data() as? [String: Bool] else {
                print("Document data was empty.")
                return
            }
            self.blockedUsers = Array(data.keys)
            print("blockedUsers is now \(self.blockedUsers)")
        }
    }

    func getChannels(forUser userId: String) {
        if userId.isEmpty {
            return
        }

        db.collection("channels/\(userId)/channels")
            .order(by: "lastUpdated", descending: true)
            .limit(to: 15)
            .addSnapshotListener({ snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "nil")")
                    return
                }

                var channels = [Channel]()
                for document in documents {
                    if let timestamp = document.get("lastUpdated") as? Timestamp,
                        let text = document.get("text") as? String {
                        let date = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
                        let seenByUser = document.get("seenByUser") as? Bool ?? true
                        let c = Channel(id: document.documentID, lastUpdated: date, text: text, seenByUser: seenByUser)
                        channels.append(c)
                    }
                }
                self.channelsFoundCompletion?(channels)
            })
    }

    func markChannelAsSeen(channel channelId: String, userId: String) {
        if channelId.isEmpty || userId.isEmpty {
            return
        }

        db.collection("channels").document(userId).collection("channels").document(channelId).updateData(["seenByUser": true]) { error in
            if let error = error {
                print("markChannelAsSeen error: \(error.localizedDescription)")
            }
        }
    }

    func updateFCMToken(withToken token: String) {
        print("Storing token to be \(token)")
        currentFCMToken = token
    }

    func updateFCMTokenForUser(userId: String) {
        print("Uploading token for user \(userId)")
        if currentFCMToken.isEmpty || userId.isEmpty {
            return
        }

        if let storedToken = UserDefaults.standard.value(forKey: "fcmtoken-\(userId)") as? String {
            if storedToken != self.currentFCMToken {
                UserDefaults.standard.set(currentFCMToken, forKey: "fcmtoken-\(userId)")
                self.updateFCMToken(forUser: userId, token: currentFCMToken)
            }
        } else {
            UserDefaults.standard.set(currentFCMToken, forKey: "fcmtoken-\(userId)")
            self.updateFCMToken(forUser: userId, token: currentFCMToken)
        }
    }

    private func updateFCMToken(forUser userId: String, token: String) {
        db.collection("userFCMTokens").document(userId).setData(["token": token], merge: true)
    }
}
