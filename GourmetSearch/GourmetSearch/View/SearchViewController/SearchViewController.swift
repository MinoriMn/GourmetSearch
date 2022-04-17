import UIKit
import Combine

class SearchViewController: UIViewController {
    private let viewModel: SearchViewModel = .init()
    private var cancellables: [AnyCancellable] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        bind(to: viewModel)
    }

    private func bind(to viewModel: SearchViewModel) {
        let output = viewModel.transform(input: .init())

        output.shops
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print(error)
                }
            }, receiveValue: { shops in
                print("shops:", shops)
                print("size:", shops.count)
                print("ex:", shops.first)
            })
            .store(in: &cancellables)
    }
}

