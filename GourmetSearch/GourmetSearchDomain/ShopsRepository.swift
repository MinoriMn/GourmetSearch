import Foundation
import Combine

typealias Range = GourmetSearchRequest.Parameter.Range
typealias Order = GourmetSearchRequest.Parameter.Order

class ShopsRepository {
    private let gourmetSearchAPI: GourmetSearchAPI

    init() {
        let plistPath: URL = R.file.apikeyPlist()!
        let keys: NSDictionary = NSDictionary(contentsOf: plistPath)!

        gourmetSearchAPI = GourmetSearchAPI(apiKey: keys["recruitApiKey"]! as! String)
    }

    public func searchShops(
        keyword: String? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        range: Range? = nil,
        genre: String? = nil,
        order: Order? = nil
    ) -> AnyPublisher<[Shop], Error> {
        gourmetSearchAPI.searchShops(
            keyword: keyword,
            lat: lat,
            lng: lng,
            range: range,
            genre: genre,
            order: order,
            start: 1,
            count: 30
        )
    }
}
