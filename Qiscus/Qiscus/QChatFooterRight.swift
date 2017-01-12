//
//  QChatFooterRight.swift
//  Example
//
//  Created by Ahmad Athaullah on 1/9/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QChatFooterRight: UICollectionReusableView {

    @IBOutlet weak var avatarImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImage.layer.cornerRadius = 19
        avatarImage.clipsToBounds = true
    }
    
    func setup(withComent comment:QiscusComment){
        let avatar = Qiscus.image(named: "in_chat_avatar")
        if let user = comment.sender{
            if QiscusHelper.isFileExist(inLocalPath: user.userAvatarLocalPath){
                avatarImage.image = UIImage.init(contentsOfFile: user.userAvatarLocalPath)
            }else{
                avatarImage.loadAsync(user.userAvatarURL, placeholderImage: avatar)
            }
        }
    }
    
    
}