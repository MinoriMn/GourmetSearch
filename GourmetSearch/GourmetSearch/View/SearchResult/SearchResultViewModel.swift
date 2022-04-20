import Combine

class SearchResultViewModel {
    private let shopsPublisher: AnyPublisher<[Shop], Never>
    private let showRoute: PassthroughSubject<Shop?, Never>
    private (set) public var shops: [Shop] = []

    private var cancellables: [AnyCancellable] = []

    init(shopsPublisher: AnyPublisher<[Shop], Never>, showRoute: PassthroughSubject<Shop?, Never>) {
        self.shopsPublisher = shopsPublisher
        self.showRoute = showRoute
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

        // TODO
        let scrollShop = Empty<Int, Never>().eraseToAnyPublisher()

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
        let scrollShop: AnyPublisher<Int, Never>
        let openShop: AnyPublisher<Shop, Never>
    }
}
