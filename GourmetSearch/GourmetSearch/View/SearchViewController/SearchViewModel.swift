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

        return .init(shops: shops)
    }
}

extension SearchViewModel {
    struct Input {

    }

    struct Output {
        let shops: AnyPublisher<[Shop], Error>
    }
}
