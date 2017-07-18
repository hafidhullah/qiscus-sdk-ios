//
//  QVCCollectionView.swift
//  Example
//
//  Created by Ahmad Athaullah on 5/16/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

// MARK: - CollectionView dataSource, delegate, and delegateFlowLayout
extension QiscusChatVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    // MARK: CollectionView Data source
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let room = self.chatRoom {
            return room.comments[section].comments.count
        }else{
            return 0
        }
    }
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let room = self.chatRoom {
            if room.comments.count > 0 {
                self.welcomeView.isHidden = true
            }else{
                self.welcomeView.isHidden = false
            }
            return room.comments.count
        }else{
            return 0
        }
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let comment = self.chatRoom!.comments[indexPath.section].comments[indexPath.item]
        
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: comment.cellIdentifier, for: indexPath) as! QChatCell
        cell.comment = comment
        
        if let audioCell = cell as? QCellAudio{
            audioCell.audioCellDelegate = self
            cell = audioCell
        }else if let postbackCell = cell as? QCellPostbackLeft{
            postbackCell.postbackDelegate = self
            cell = postbackCell
        }
        
        return cell
    }
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let commentGroup = self.chatRoom!.comments[indexPath.section]
        
        if kind == UICollectionElementKindSectionFooter{
            if commentGroup.senderEmail == QiscusMe.sharedInstance.email{
                let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterRight", for: indexPath) as! QChatFooterRight
                return footerCell
            }else{
                let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterLeft", for: indexPath) as! QChatFooterLeft
                footerCell.sender = commentGroup.sender
                return footerCell
            }
        }else{
            let headerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellHeader", for: indexPath) as! QChatHeaderCell
        
            headerCell.dateString = commentGroup.date
            return headerCell
        }
    }
    
    // MARK: CollectionView delegate
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        /*
        if let targetCell = cell as? QChatCell{
            if !targetCell.data.userIsOwn && targetCell.data.commentStatus != .read{
                publishRead()
                var i = 0
                for index in unreadIndexPath{
                    if index.row == indexPath.row && index.section == indexPath.section{
                        unreadIndexPath.remove(at: i)
                        break
                    }
                    i += 1
                }
            }
        }
        if indexPath.section == (comments.count - 1){
            if indexPath.row == comments[indexPath.section].count - 1{
                isLastRowVisible = true
            }
        }
        */
    }
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        /*
        if indexPath.section == (comments.count - 1){
            if indexPath.row == comments[indexPath.section].count - 1{
                let visibleIndexPath = collectionView.indexPathsForVisibleItems
                if visibleIndexPath.count > 0{
                    var visible = false
                    for visibleIndex in visibleIndexPath{
                        if visibleIndex.row == indexPath.row && visibleIndex.section == indexPath.section{
                            visible = true
                            break
                        }
                    }
                    isLastRowVisible = visible
                }else{
                    isLastRowVisible = true
                }
            }
        }
        */
    }
    public func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    public func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        let comment = self.chatRoom?.comments[indexPath.section].comments[indexPath.row]
        var show = false
        switch action.description {
        case "copy:":
            if comment?.type == .text{
                show = true
            }
            break
        case "resend":
            if comment?.status == .failed && Qiscus.sharedInstance.connected {
                if comment?.type == .text{
                    show = true
                }
//                else{
//                    if let file = QiscusFile.file(forComment: commentData){
//                        if file.isUploaded || file.isOnlyLocalFileExist{
//                            show = true
//                        }
//                    }
//                }
            }
            break
        case "deleteComment":
            if comment?.status == .failed  {
                show = true
            }
            break
        case "reply":
            if comment?.type != .postback && comment?.type != .account && comment?.status != .failed && comment?.type != .system && Qiscus.sharedInstance.connected{
                show = true
            }
            break
        default:
            break
        }
    
        return show
    }
    public func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        let textComment = self.comments[indexPath.section][indexPath.row]
        
        if action == #selector(UIResponderStandardEditActions.copy(_:)) && textComment.commentType == .text{
            UIPasteboard.general.string = textComment.commentText
        }
    }
    // MARK: CollectionView delegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height = CGFloat(0)
        if section > 0 {
            let commentGroup = self.chatRoom?.comments[section]
            let commentGroupBefore = self.chatRoom?.comments[section - 1]
            if commentGroup!.date != commentGroupBefore!.date{
                height = 35
            }
        }else{
            height = 35
        }
        return CGSize(width: collectionView.bounds.size.width, height: height)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        var height = CGFloat(0)
        var width = CGFloat(0)
        let commentGroup = self.chatRoom?.comments[section]
        if commentGroup?.senderEmail != QiscusMe.sharedInstance.email{
            height = 44
            width = 44
        }
        return CGSize(width: width, height: height)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let commentGroup = self.chatRoom?.comments[section]
        if commentGroup?.senderEmail != QiscusMe.sharedInstance.email{
            return UIEdgeInsets(top: 0, left: 0, bottom: -44, right: 0)
        }else{
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let comment = self.chatRoom!.comments[indexPath.section].comments[indexPath.row]
        var size = comment.textSize
        size.width = QiscusHelper.screenWidth() - 16
        
        if comment.type == .video || comment.type == .image {
            size.height = 190
        }else{
            size.height += 20
        }
        
        if comment.type == .text || comment.type == .postback || comment.type == .account || comment.type == .reply{
            if comment.type == .reply{
                size.height += 75
            }
        }
        if (comment.type != .system && indexPath.row == 0) {
            size.height += 20
        }
        return size
    }
    
}
