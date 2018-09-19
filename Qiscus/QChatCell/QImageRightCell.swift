//
//  QImageRightCell.swift
//  Qiscus
//
//  Created by asharijuang on 05/09/18.
//

import UIKit
import QiscusCore
import QiscusUI
import AlamofireImage
import Alamofire
import SimpleImageViewer

class QImageRightCell: UIBaseChatCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var tvContent: UILabel!
    @IBOutlet weak var ivBaloonLeft: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var ivStatus: UIImageView!
    @IBOutlet weak var btnDownload: UIButton!
    @IBOutlet weak var ivComment: UIImageView!
    
    @IBOutlet weak var progressContainer: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var lbNameHeight: NSLayoutConstraint!
    @IBOutlet weak var lbNameLeading: NSLayoutConstraint!
    @IBOutlet weak var lbNameTrailing: NSLayoutConstraint!
    @IBOutlet weak var statusWidth: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.ivComment.contentMode = .scaleAspectFill
        self.ivComment.clipsToBounds = true
        self.ivComment.backgroundColor = UIColor.black
        self.ivComment.isUserInteractionEnabled = true
        self.progressContainer.layer.cornerRadius = 20
        self.progressContainer.clipsToBounds = true
        self.progressContainer.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.65).cgColor
        self.progressContainer.layer.borderWidth = 2
        self.progressView.backgroundColor = UIColor.green
        let imgTouchEvent = UITapGestureRecognizer(target: self, action: #selector(QImageLeftCell.imageDidTap))
        self.ivComment.addGestureRecognizer(imgTouchEvent)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func present(message: CommentModel) {
        self.bindData(message: message)
    }
    
    override func update(message: CommentModel) {
        self.bindData(message: message)
    }
    
    func bindData(message: CommentModel){
        self.setupBalon()
        self.status(message: message)
        
        // get image
        self.lbName.text = "You"
        self.lbTime.text = self.hour(date: message.date())
        print("payload: \(message.payload)")
        guard let payload = message.payload else { return }
        let caption = payload["caption"] as? String
        
        self.tvContent.text = caption
        self.tvContent.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
        if let url = payload["url"] as? String {
            if let url = payload["url"] as? String {
                ivComment.sd_setShowActivityIndicatorView(true)
                ivComment.sd_setIndicatorStyle(.gray)
                ivComment.sd_setImage(with: URL(string: url)!)
            }
        }
        
    }
    
    @objc func imageDidTap() {
        let configuration = ImageViewerConfiguration { config in
            config.imageView = ivComment
        }
        
        let imageViewerController = ImageViewerController(configuration: configuration)
        self.currentViewController()?.navigationController?.present(ImageViewerController(configuration: configuration), animated: true)
    }
    
    func currentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return currentViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            
            if let top = moreNavigationController.topViewController, top.view.window != nil {
                return currentViewController(base: top)
            } else if let selected = tab.selectedViewController {
                return currentViewController(base: selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return currentViewController(base: presented)
        }
        
        return base
    }
    
    func setupBalon(){
        self.ivBaloonLeft.image = self.getBallon()
        self.ivBaloonLeft.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
    }
    
    func status(message: CommentModel){
        
        switch message.status {
        case .deleted:
            ivStatus.image = Qiscus.image(named: "ic_deleted")?.withRenderingMode(.alwaysTemplate)
            break
        case .sending, .pending:
            lbTime.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            lbTime.text = QiscusTextConfiguration.sharedInstance.sendingText
            ivStatus.image = Qiscus.image(named: "ic_info_time")?.withRenderingMode(.alwaysTemplate)
            break
        case .sent:
            lbTime.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.image = Qiscus.image(named: "ic_sending")?.withRenderingMode(.alwaysTemplate)
            break
        case .delivered:
            lbTime.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.image = Qiscus.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
            break
        case .read:
            lbTime.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.tintColor = Qiscus.style.color.readMessageColor
            ivStatus.image = Qiscus.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
            break
        case . failed:
            lbTime.textColor = QiscusColorConfiguration.sharedInstance.failToSendColor
            lbTime.text = QiscusTextConfiguration.sharedInstance.failedText
            ivStatus.image = Qiscus.image(named: "ic_warning")?.withRenderingMode(.alwaysTemplate)
            ivStatus.tintColor = QiscusColorConfiguration.sharedInstance.failToSendColor
            break
        }
    }
    
    func hour(date: Date?) -> String {
        guard let date = date else {
            return "-"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone      = TimeZone.current
        let defaultTimeZoneStr = formatter.string(from: date);
        return defaultTimeZoneStr
    }
    
}