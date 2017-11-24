//
//  QUser.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import RealmSwift

@objc public protocol QUserDelegate {
    @objc optional func user(didChangeName fullname:String)
    @objc optional func user(didChangeAvatarURL avatarURL:String)
    @objc optional func user(didChangeAvatar avatar:UIImage)
    @objc optional func user(didChangeLastSeen lastSeen:Double)
}
@objc public enum QUserPresence:Int {
    case offline,online
}
public class QUser:Object {
    static var cache = [String: QUser]()
    
    @objc public dynamic var email:String = ""
    @objc public dynamic var id:Int = 0
    @objc public dynamic var avatarURL:String = ""
    @objc public dynamic var avatarLocalPath:String = ""
    @objc public dynamic var storedName:String = ""
    @objc public dynamic var definedName:String = ""
    @objc public dynamic var lastSeen:Double = 0
    @objc internal dynamic var rawPresence:Int = 0
    
    public var fullname:String{
        if self.definedName != "" {
            return self.definedName
        }else{
            return self.storedName
        }
    }
    public var presence:QUserPresence {
        get{
            return QUserPresence(rawValue: self.rawPresence)!
        }
    }
    public var avatar:UIImage?{
        didSet{
            let email = self.email
            let avatar = self.avatar
            if self.avatar != nil {
                DispatchQueue.main.async {autoreleasepool {
                    QUser.cache[email]?.delegate?.user?(didChangeAvatar: avatar!)
                }}
            }
        }
    }
    public var delegate:QUserDelegate?
    
    public var lastSeenString:String{
        get{
            if self.lastSeen == 0 {
                return ""
            }else{
                var result = ""
                let date = Date(timeIntervalSince1970: self.lastSeen)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d MMMM yyyy"
                let dateString = dateFormatter.string(from: date)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                let timeString = timeFormatter.string(from: date)
                
                let now = Date()

                let secondDiff = now.offsetFromInSecond(date: date)
                let minuteDiff = Int(secondDiff/60)
                let hourDiff = Int(minuteDiff/60)
                
                if secondDiff < 60 {
                    result = "few seconds ago"
                }
                else if minuteDiff == 1 {
                    result = "a minute ago"
                }
                else if minuteDiff < 60 {
                    result = "\(Int(secondDiff/60)) minute ago"
                }else if hourDiff == 1{
                    result = "an hour ago"
                }else if hourDiff < 6 {
                    result = "\(hourDiff) hours ago"
                }
                else if date.isToday{
                    result = "today at \(timeString)"
                }
                else if date.isYesterday{
                    result = "yesterday at \(timeString)"
                }
                else{
                    result = "\(dateString) at \(timeString)"
                }
                
                return result
            }
        }
    }
    
    // MARK: - Unstored properties
    override public static func ignoredProperties() -> [String] {
        return ["avatar","delegate"]
    }
    public class func saveUser(withEmail email:String, id:Int? = nil ,fullname:String? = nil, avatarURL:String? = nil, lastSeen:Double? = nil)->QUser{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var user = QUser()
        if let savedUser = QUser.user(withEmail: email){
            user = savedUser
            if fullname != nil  && fullname! != user.storedName {
                try! realm.write {
                    user.storedName = fullname!
                }
                if user.definedName != "" {
                    user.delegate?.user?(didChangeName: fullname!)
                }
            }
            if id != nil {
                try! realm.write {
                    user.id = id!
                }
            }
            if avatarURL != nil && avatarURL! != user.avatarURL{
                try! realm.write {
                    user.avatarURL = avatarURL!
                }
                user.delegate?.user?(didChangeAvatarURL: avatarURL!)
            }
            if lastSeen != nil && lastSeen! > user.lastSeen{
                try! realm.write {
                    user.lastSeen = lastSeen!
                }
                user.delegate?.user?(didChangeLastSeen: lastSeen!)
            }
        }else{
            user.email = email
            if fullname != nil {
                user.storedName = fullname!
            }
            if avatarURL != nil {
                user.avatarURL = avatarURL!
            }
            if lastSeen != nil {
                user.lastSeen = lastSeen!
            }
            if id != nil {
                user.id = id!
            }
            try! realm.write {
                realm.add(user)
            }
            if Thread.isMainThread {
                user.cacheObject()
            }
        }
        
        return user
    }
    internal class func getUser(email:String) -> QUser? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data = realm.objects(QUser.self).filter("email == '\(email)'")
        print("user data count: \(data.count) for email: \(email)")
        if data.count > 0 {
            let user = data.first!
            return user
        }
        return nil
    }
    public class func user(withEmail email:String) -> QUser? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if let cachedUser = QUser.cache[email] {
            if !cachedUser.isInvalidated {
                return cachedUser
            }
        }
        let data = realm.objects(QUser.self).filter("email == '\(email)'")
        if data.count > 0 {
            let user = data.first!
            user.cacheObject()
            user.subscribeRealtimeStatus()
            return user
        }
        return nil
    }
    public func subscribeRealtimeStatus(){
        let channel = "u/\(self.email)/s"
        Qiscus.shared.mqtt?.subscribe(channel)
    }
    public func updatePresence(presence:QUserPresence){
        let email = self.email
        QiscusDBThread.async {
            if let user = QUser.getUser(email: email){
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                try! realm.write {
                    user.rawPresence = presence.rawValue
                }
                DispatchQueue.main.sync {
                    if let updatedUser = QUser.user(withEmail: email){
                        QiscusNotification.publish(userPresence: updatedUser)
                    }
                }
            }
        }
    }
    public func updateLastSeen(lastSeen:Double){
        let email = self.email
        QiscusDBThread.async {
            if let user = QUser.getUser(email: email){
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                if lastSeen > user.lastSeen {
                    try! realm.write {
                        user.lastSeen = lastSeen
                    }
                    DispatchQueue.main.async {
                        if let room = QRoom.room(withUser: email) {
                            if let mainUser = QUser.user(withEmail: email){
                                room.delegate?.room(didChangeUser: room, user: mainUser)
                            }
                        }
                    }
                }
            }
        }
    }
    public func setName(name:String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if name != self.definedName {
            try! realm.write {
                self.definedName = name
            }
            self.delegate?.user?(didChangeName: name)
        }
    }
    public func saveAvatar(withImage image:UIImage){
        if !self.isInvalidated {
            self.avatar = image
            var filename = self.email.replacingOccurrences(of: ".", with: "_").replacingOccurrences(of: "@", with: "_")
            QiscusFileThread.async {autoreleasepool{
                var ext = "png"
                var avatarData:Data? = nil
                if let data = UIImagePNGRepresentation(image) {
                    avatarData = data
                }else if let data = UIImageJPEGRepresentation(image, 1.0) {
                    avatarData = data
                    ext = "jpg"
                }
                filename = "\(filename).\(ext)"
                if avatarData != nil {
                    let localPath = QFileManager.saveFile(withData: avatarData!, fileName: filename, type: .user)
                    DispatchQueue.main.async {autoreleasepool{
                        if !self.isInvalidated {
                            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                            try! realm.write {
                                self.avatarLocalPath = localPath
                            }
                        }
                    }}
                }
            }}
        }
    }
    public class func all() -> [QUser]{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data = realm.objects(QUser.self)
        
        if data.count > 0 {
            return Array(data)
        }else{
            return [QUser]()
        }
    }
    internal class func cacheAll(){
        let users = QUser.all()
        for user in users{
            if QUser.cache[user.email] == nil {
                QUser.cache[user.email] = user
            }
        }
    }
    public func clearLocalPath(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.avatarLocalPath = ""
        }
    }
    internal func cacheObject(){
        if Thread.isMainThread {
            if QUser.cache[self.email] == nil {
                QUser.cache[self.email] = self
            }
        }
    }
}
