import Combine

class ShopDetailViewModel {
    private var cancellables: [AnyCancellable] = []

    @Published private (set) public var shop: Shop

    init(shop: Shop) {
        self.shop = shop
    }

    func transform(input: Input) -> Output {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        return .init(
            shop: $shop.eraseToAnyPublisher()
        )
    }
}

extension ShopDetailViewModel {
    struct Input {
    }

    struct Output {
        let shop: AnyPublisher<Shop, Never>
    }
}
