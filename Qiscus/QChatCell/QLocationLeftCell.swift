//
//  QLocationLeftCell.swift
//  Qiscus
//
//  Created by asharijuang on 05/09/18.
//

import UIKit
import QiscusUI
import QiscusCore
import MapKit
import SwiftyJSON

class QLocationLeftCell: UIBaseChatCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbTime: UILabel!
    
    @IBOutlet weak var ivBaloon: UIImageView!
    @IBOutlet weak var ivStatus: UIImageView!
    @IBOutlet weak var locationContainer: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressView: UITextView!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QLocationLeftCell.openMap))
        self.mapView.addGestureRecognizer(tapRecognizer)
        self.locationContainer.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func present(message: CommentModel) {
        // parsing payload
        self.bindData(message: message)
        
    }
    
    override func update(message: CommentModel) {
        self.bindData(message: message)
    }
    
    func bindData(message: CommentModel){
        self.setupBalon()
        
        self.lbName.text = message.username
        self.lbTime.text = message.hour()
        let data = message.payload
        let payload = JSON(data)
        
        self.locationLabel.text = payload["name"].stringValue
        let address = payload["address"].stringValue
        self.addressView.text = address
        
        let lat = CLLocationDegrees(payload["latitude"].doubleValue)
        let long = CLLocationDegrees(payload["longitude"].doubleValue)
        
        let center = CLLocationCoordinate2DMake(lat, long)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        let newPin = MKPointAnnotation()
        newPin.coordinate = center
        self.mapView.setRegion(region, animated: false)
        self.mapView.addAnnotation(newPin)
    
    }
    
    func setupBalon(){
        self.ivBaloon.image = self.getBallon()
        self.ivBaloon.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
    }
    
    @objc func openMap(){
        let payload = JSON(self.comment?.payload)
        
        let latitude: CLLocationDegrees = payload["latitude"].doubleValue
        let longitude: CLLocationDegrees = payload["longitude"].doubleValue
        
        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = payload["name"].stringValue
        mapItem.openInMaps(launchOptions: options)
    }

    
}
