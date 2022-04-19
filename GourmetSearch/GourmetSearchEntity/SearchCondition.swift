import Foundation
import CoreLocation

struct SearchCondition {
    var keyword: String?
    var coord: CLLocationCoordinate2D
    var range: Range
    var genre: String?
    var order: Order
    var isLunch: Bool
    var isPet: Bool
    var isParking: Bool
}
