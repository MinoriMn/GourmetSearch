import Foundation
import MapKit
import UIKit

// 参考: https://blog.fenrir-inc.com/jp/2018/01/ios11_annotation_clustering.html
class ShopAnnotation: NSObject, MKAnnotation {

    static let clusteringIdentifier = "Shop"

    let coordinate: CLLocationCoordinate2D

    let glyphImage: UIImage

    let glyphTintColor: UIColor

    let markerTintColor: UIColor

    var title: String? = nil

    init(_ coordinate: CLLocationCoordinate2D, glyphImage: UIImage, glyphTintColor: UIColor, markerTintColor: UIColor) {
        self.coordinate = coordinate
        self.glyphImage = glyphImage
        self.glyphTintColor = glyphTintColor
        self.markerTintColor = markerTintColor
    }

}
