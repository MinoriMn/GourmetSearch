import Combine

class SearchUseCase {
    private let shopsRepository: ShopsRepository

    init() {
        shopsRepository = .init()
    }

    public func shopsSearchByGPS(
        keyword: String? = nil,
        lat: Float? = nil,
        lng: Float? = nil,
        range: Range? = nil,
        genre: String? = nil,
        order: Order? = nil
    ) -> AnyPublisher<[Shop], Error> {
        shopsRepository.searchShops(keyword: keyword, lat: lat, lng: lng, range: range, genre: genre, order: order)
    }
}
