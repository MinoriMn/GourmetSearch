import Foundation
import Combine

typealias Range = GourmetSearchRequest.Parameter.Range
typealias Order = GourmetSearchRequest.Parameter.Order

class ShopsRepository {
    private let gourmetSearchAPI = GourmetSearchAPI(apiKey: PlistReader(forResource: "apikey").getValue(key: "recruitApiKey") as! String)

    public func searchShops(
        keyword: String? = nil,
        lat: Float? = nil,
        lng: Float? = nil,
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
            count: 50
        )
    }
}
