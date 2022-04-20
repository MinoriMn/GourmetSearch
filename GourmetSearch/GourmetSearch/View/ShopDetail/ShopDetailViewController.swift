import Foundation
import Combine
import CombineCocoa
import UIKit
import Nuke

class ShopDetailViewController: UIViewController {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var urlLabel: UILabel!
    @IBOutlet private weak var openingLabel: UILabel!
    @IBOutlet private weak var dinnerLabel: UILabel!

    private let viewModel: ShopDetailViewModel
    private var cancellables: [AnyCancellable] = []

    init?(coder: NSCoder, shop: Shop) {
        self.viewModel = .init(shop: shop)

        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.isHidden = false

        bind(to: viewModel)
    }

    private func bind(to viewModel: ShopDetailViewModel) {
        let output = viewModel.transform(input: .init())

        output.shop
            .sink { [weak self] shop in
                self?.title = shop.name
                if let imageView = self?.imageView, let url = URL(string: shop.photo?.pc?.l ?? "") {
                    Nuke.loadImage(with: url, into: imageView)
                }
                self?.addressLabel.text = shop.address
                self?.urlLabel.text = shop.urls?.pc
                self?.openingLabel.text = shop.open
                self?.dinnerLabel.text = shop.budget?.average
            }
            .store(in: &cancellables)
    }
}
