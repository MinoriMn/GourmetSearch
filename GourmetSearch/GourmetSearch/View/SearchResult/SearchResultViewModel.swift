import Combine

class SearchResultViewModel {
    private let shopsPublisher: AnyPublisher<[Shop], Never>
    private let showRoute: PassthroughSubject<Shop?, Never>
    private let scrollToShop: AnyPublisher<Shop, Never>
    private (set) public var shops: [Shop] = []

    private var cancellables: [AnyCancellable] = []

    init(shopsPublisher: AnyPublisher<[Shop], Never>, showRoute: PassthroughSubject<Shop?, Never>, scrollToShop: AnyPublisher<Shop, Never>) {
        self.shopsPublisher = shopsPublisher
        self.showRoute = showRoute
        self.scrollToShop = scrollToShop
    }

    func transform(input: Input) -> Output {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        input.collectionScrolledPublisher
            .sink { [weak self] index in
                guard let self = self else { return }
                guard !self.shops.isEmpty, index >= 0, index < self.shops.count else {
                    // TODO: error
                    print("index(\(index)) is out of shops' index")
                    return
                }
                self.showRoute.send(self.shops[index])
            }
            .store(in: &cancellables)
        
        let updateShops = shopsPublisher
            .map { [weak self] shops -> [Shop] in
                self?.shops = shops
                return shops
            }
            .eraseToAnyPublisher()

        let scrollShop = scrollToShop
            .flatMap { [weak self] shop -> AnyPublisher<Int, Error> in
                guard let self = self else { return Fail(error: CommonError.couldNotFoundSelf).eraseToAnyPublisher() }
                guard let index = self.shops.firstIndex(of: shop) else { return Fail(error: ModelError.givenShopIsOutOfIndex).eraseToAnyPublisher() }
                return Just(index).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()

        // TODO
        let openShop = Empty<Shop, Never>().eraseToAnyPublisher()

        return .init(
            updateShops: updateShops,
            scrollShop: scrollShop,
            openShop: openShop
        )
    }
}

extension SearchResultViewModel {
    struct Input {
        let collectionScrolledPublisher: AnyPublisher<Int, Never>
    }

    struct Output {
        let updateShops: AnyPublisher<[Shop], Never>
        let scrollShop: AnyPublisher<Int, Error>
        let openShop: AnyPublisher<Shop, Never>
    }
}

extension SearchResultViewModel {
    enum ModelError: Error {
        case givenShopIsOutOfIndex
    }
}
