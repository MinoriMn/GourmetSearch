import Combine
import CoreLocation

class SearchViewModel {
    private var cancellables: [AnyCancellable] = []

    private let usecase = SearchUseCase()

    private var shops: [Shop] = []

    private (set) public var searchCondition: SearchCondition = .init(
        keyword: nil,
        coord: .init(latitude: 35.688904, longitude: 139.696422),
        range: .u1000m,
        genre: nil,
        order: .recommendation,
        isLunch: false,
        isPet: false,
        isParking: false
    )
    let sendSearchCondition = PassthroughSubject<SearchCondition, Never>()
    let scrollToShop = PassthroughSubject<Shop, Never>()

    func transform(input: Input) -> Output {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        let shops = input.search.flatMap { [weak self] searchCondition, coord -> AnyPublisher<[Shop], Error> in
            guard let self = self else { return Fail(error: CommonError.couldNotFoundSelf).eraseToAnyPublisher() }
            guard let coord = coord else { return Fail(error: CommonError.couldNotGetUserLocation).eraseToAnyPublisher() }

            self.searchCondition = searchCondition
            self.searchCondition.coord = coord

            return self.usecase.shopsSearchByGPS(
                keyword: self.searchCondition.keyword,
                lat: self.searchCondition.coord.latitude,
                lng: self.searchCondition.coord.longitude,
                range: self.searchCondition.range,
                genre: self.searchCondition.genre,
                lunch: self.searchCondition.isLunch,
                pet: self.searchCondition.isPet,
                parking: self.searchCondition.isParking,
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
            .map { [weak self] void -> Void in
                guard let self = self else { return void }
                self.sendSearchCondition.send(self.searchCondition)
                return void
            }
            .eraseToAnyPublisher()

        let openSearchResult = Publishers.Merge(input.searchResultButtonTapped, input.setectedPin.map { _ in Void() }.eraseToAnyPublisher())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        input.setectedPin
            .sink { [weak self] index in
                guard let self = self else { return /*TODO*/ }
                guard !self.shops.isEmpty, index >= 0, index < self.shops.count else {
                    print(ModelError.notFindShopByIndex)
                    return /*TODO*/
                }
                self.scrollToShop.send(self.shops[index])
            }
            .store(in: &cancellables)

        return .init(
            shops: shops,
            closeToCurrentLocation: closeToCurrentLocation,
            openSearchCondition: openSearchCondition,
            openSearchResult: openSearchResult
        )
    }
}

extension SearchViewModel {
    struct Input {
        let search: AnyPublisher<(SearchCondition, CLLocationCoordinate2D?), Never>
        let locationButtonTapped: AnyPublisher<Void, Never>
        let conditionButtonTapped: AnyPublisher<Void, Never>
        let searchResultButtonTapped: AnyPublisher<Void, Never>
        let setectedPin: AnyPublisher<Int, Never>
    }

    struct Output {
        let shops: AnyPublisher<[Shop], Error>
        let closeToCurrentLocation: AnyPublisher<Void, Error>
        let openSearchCondition: AnyPublisher<Void, Error>
        let openSearchResult: AnyPublisher<Void, Error>
    }
}

extension SearchViewModel {
    enum ModelError: Error {
        case notFindShopByIndex
    }
}
