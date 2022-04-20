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
        range: GourmetSearchRequest.Parameter.Range? = nil,
        genre: String? = nil,
        lunch: Bool = false,
        pet: Bool = false,
        parking: Bool = false,
        order: GourmetSearchRequest.Parameter.Order? = nil
    ) -> AnyPublisher<[Shop], Error> {
        gourmetSearchAPI.searchShops(
            keyword: keyword,
            lat: lat,
            lng: lng,
            range: range,
            genre: genre,
            lunch: lunch,
            pet: pet,
            parking: parking,
            order: order,
            start: 1,
            count: 30
        )
    }
}
