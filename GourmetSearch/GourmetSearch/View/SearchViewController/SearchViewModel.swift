import Combine
import CoreLocation

class SearchViewModel {
    private var cancellables: [AnyCancellable] = []

    private let usecase = SearchUseCase()

    private var shops: [Shop] = []

    private var searchCondition: SearchCondition = .init(
        keyword: nil,
        coord: .init(latitude: 35.688904, longitude: 139.696422),
        range: .u1000m,
        genre: nil,
        order: .recommendation
    )

    func transform(input: Input) -> Output {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        let shops = input.search.flatMap { [weak self] coord -> AnyPublisher<[Shop], Error> in
            guard let self = self else { return Fail(error: CommonError.couldNotFoundSelf).eraseToAnyPublisher() }
            guard let coord = coord else { return Fail(error: CommonError.couldNotGetUserLocation).eraseToAnyPublisher() }

            self.searchCondition.coord = coord

            return self.usecase.shopsSearchByGPS(
                keyword: self.searchCondition.keyword,
                lat: self.searchCondition.coord.latitude,
                lng: self.searchCondition.coord.longitude,
                range: self.searchCondition.range,
                genre: self.searchCondition.genre,
                order: self.searchCondition.order
            )
        }
            .map { [weak self] shops -> [Shop] in
                self?.shops = shops
                return shops
            }
            .eraseToAnyPublisher()

        let closeToCurrentLocation = input.locationButtonTapped
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let openSearchCondition = input.conditionButtonTapped
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let openSearchResult = input.searchResultButtonTapped
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        return .init(
            shops: shops,
            closeToCurrentLocation: closeToCurrentLocation,
            openSearchCondition: openSearchCondition,
            openSearchResult: openSearchResult
        )
    }
}

extension SearchViewModel {
    struct SearchCondition {
        var keyword: String?
        var coord: CLLocationCoordinate2D
        var range: Range
        var genre: String?
        var order: Order
    }
}

extension SearchViewModel {
    struct Input {
        let search: AnyPublisher<CLLocationCoordinate2D?, Never>
        let locationButtonTapped: AnyPublisher<Void, Never>
        let conditionButtonTapped: AnyPublisher<Void, Never>
        let searchResultButtonTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let shops: AnyPublisher<[Shop], Error>
        let closeToCurrentLocation: AnyPublisher<Void, Error>
        let openSearchCondition: AnyPublisher<Void, Error>
        let openSearchResult: AnyPublisher<Void, Error>
    }
}
