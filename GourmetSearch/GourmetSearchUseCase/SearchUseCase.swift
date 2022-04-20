import Combine

class SearchUseCase {
    private let shopsRepository: ShopsRepository

    init() {
        shopsRepository = .init()
    }

    public func shopsSearchByGPS(
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
        shopsRepository.searchShops(
            keyword: keyword,
            lat: lat,
            lng: lng,
            range: range,
            genre: genre,
            lunch: lunch,
            pet: pet,
            parking: parking,
            order: order
        )
    }
}
