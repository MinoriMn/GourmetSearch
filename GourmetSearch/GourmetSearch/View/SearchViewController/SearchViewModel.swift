import Combine

class SearchViewModel {
    private var cancellables: [AnyCancellable] = []

    private let usecase = SearchUseCase()

    func transform(input: Input) -> Output {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        // TODO:
        let shops = Just(Void()).flatMap { [weak self] _ -> AnyPublisher<[Shop], Error> in
            guard let self = self else { return Fail(error: CommonError.couldNotFoundSelf).eraseToAnyPublisher() }
            return self.usecase.shopsSearchByGPS(keyword: nil, lat: 35.688904, lng: 139.696422, range: .u3000m, genre: nil, order: .recommendation)
        }
            .eraseToAnyPublisher()

        let closeToCurrentLocation = input.locationButtonTapped
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let openSearchCondition = input.conditionButtonTapped
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let openSearchResult = input.searchButtonTapped
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
    struct Input {
        let locationButtonTapped: AnyPublisher<Void, Never>
        let conditionButtonTapped: AnyPublisher<Void, Never>
        let searchButtonTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let shops: AnyPublisher<[Shop], Error>
        let closeToCurrentLocation: AnyPublisher<Void, Error>
        let openSearchCondition: AnyPublisher<Void, Error>
        let openSearchResult: AnyPublisher<Void, Error>
    }
}
