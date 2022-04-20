import Combine

class ConditionViewModel {
    private var cancellables: [AnyCancellable] = []

    private let usecase = SearchUseCase()

    private var shops: [Shop] = []

    @Published private var searchCondition: SearchCondition? = nil
    private let initSearchConditionPublisher: AnyPublisher<SearchCondition, Never>
    private let searchConditionPublisher: PassthroughSubject<SearchCondition, Never>

    init(initSearchConditionPublisher: AnyPublisher<SearchCondition, Never>, searchConditionPublisher: PassthroughSubject<SearchCondition, Never>) {
        self.initSearchConditionPublisher = initSearchConditionPublisher
        self.searchConditionPublisher = searchConditionPublisher
    }

    func transform(input: Input) -> Output {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        input.distanceSelected
            .sink { [weak self] range in
                self?.searchCondition?.range = range
            }
            .store(in: &cancellables)

        input.keywordChanged
            .sink { [weak self] text in
                self?.searchCondition?.keyword = text
            }
            .store(in: &cancellables)

        input.lunchButtonTapped
            .sink { [weak self] isON in
                self?.searchCondition?.isLunch = isON
            }
            .store(in: &cancellables)

        input.petButtonTapped
            .sink { [weak self] isON in
                self?.searchCondition?.isPet = isON
            }
            .store(in: &cancellables)

        input.parkingButtonTapped
            .sink { [weak self] isON in
                self?.searchCondition?.isParking = isON
            }
            .store(in: &cancellables)

        self.initSearchConditionPublisher
            .sink { [weak self] searchCondition in
                self?.searchCondition = searchCondition
            }
            .store(in: &cancellables)

        let setSearchCondition = $searchCondition
            .flatMap { searchCondition -> AnyPublisher<SearchCondition, Never> in
                guard let searchCondition = searchCondition else { return Empty<SearchCondition, Never>().eraseToAnyPublisher() }
                return Just(searchCondition).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()

        let close = Publishers.Merge(
            input.searchButtonTapped
                .flatMap { [weak self] _ -> AnyPublisher<Void, Never> in
                    // 検索条件を最初の画面に送信
                    if let self = self, let searchCondition = self.searchCondition {
                        self.searchConditionPublisher.send(searchCondition)
                    }
                    return Just(Void()).eraseToAnyPublisher()
                },
            input.cancelButtonTapped
        )
            .eraseToAnyPublisher()

        return .init(
            setSearchCondition: setSearchCondition,
            close: close
        )
    }
}

extension ConditionViewModel {
    struct Input {
        let distanceSelected: AnyPublisher<Range, Never>
        let keywordChanged: AnyPublisher<String?, Never>
        let lunchButtonTapped: AnyPublisher<Bool, Never>
        let petButtonTapped: AnyPublisher<Bool, Never>
        let parkingButtonTapped: AnyPublisher<Bool, Never>
        let cancelButtonTapped: AnyPublisher<Void, Never>
        let searchButtonTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let setSearchCondition: AnyPublisher<SearchCondition, Never>
        let close: AnyPublisher<Void, Never>
    }
}
