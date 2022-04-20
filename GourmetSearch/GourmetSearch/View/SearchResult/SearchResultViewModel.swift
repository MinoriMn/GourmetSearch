import Combine

class SearchResultViewModel {
    private let shopsPublisher: AnyPublisher<[Shop], Never>
    private (set) public var shops: [Shop] = []

    private var cancellables: [AnyCancellable] = []

    init(shopsPublisher: AnyPublisher<[Shop], Never>) {
        self.shopsPublisher = shopsPublisher
    }

    func transform(input: Input) -> Output {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
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

    }

    struct Output {
        let updateShops: AnyPublisher<[Shop], Never>
        let scrollShop: AnyPublisher<Int, Never>
        let openShop: AnyPublisher<Shop, Never>
    }
}
