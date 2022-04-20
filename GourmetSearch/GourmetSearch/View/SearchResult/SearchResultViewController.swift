import Foundation
import Combine
import CombineCocoa
import UIKit
import Nuke

class SearchResultViewController: UIViewController {
    @IBOutlet private weak var shopCollectionView: UICollectionView! {
        didSet {
            shopCollectionView.register(UINib(nibName: ShopCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: ShopCollectionViewCell.identifier)
            shopCollectionView.dataSource = self
            shopCollectionView.delegate = self
        }
    }
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var pageLabel: UILabel!

    private let viewModel: SearchResultViewModel
    private var cancellables: [AnyCancellable] = []

    private let index = CurrentValueSubject<Int, Never>(0)

    init?(coder: NSCoder, shopsPublisher: AnyPublisher<[Shop], Never>, showRoute: PassthroughSubject<Shop?, Never>, scrollToShop: AnyPublisher<Shop, Never>) {
        self.viewModel = .init(shopsPublisher: shopsPublisher, showRoute: showRoute, scrollToShop: scrollToShop)

        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bind(to: viewModel)
    }

    override func viewWillAppear(_ animated: Bool) {
        let x = self.shopCollectionView.contentOffset.x
        let i = Int(x / (ShopCollectionViewCell.cellWidth + 75)) // TODO: 定数を調整
        self.index.send(i)

        super.viewWillAppear(animated)
    }

    private func bind(to viewModel: SearchResultViewModel) {
        closeButton.tapPublisher
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)

        index
            .sink { [weak self] index in
                self?.pageLabel.text = "\(index + 1) / \(self?.viewModel.shops.count ?? 0)"
            }
            .store(in: &cancellables)

        // 複数の購読を実行すると最後に購読したもの以外はキャンセルされてしまうらしい
//        shopCollectionView.didSelectItemPublisher
//            .sink { [weak self] index in
//                guard let self = self else { return }
//                //セルがタップされた時の処理
//                let viewController = R.storyboard.shopDetailViewController().instantiateInitialViewController { [weak self] coder in
//                    guard let self = self else { return nil }
//                    return ShopDetailViewController(
//                        coder: coder,
//                        shop: self.viewModel.shops[index.item]
//                    )
//                }
//                if let viewController = viewController {
//                    self.present(viewController, animated: true)
//                }
//            }
//            .store(in: &cancellables)
//
//        shopCollectionView.didScrollPublisher
//            .sink { [weak self] _ in
//                if let x = self?.shopCollectionView.contentOffset.x {
//                    let i = Int(x / (ShopCollectionViewCell.cellWidth + 75)) // TODO: 定数を調整
//                    if i != self?.index.value {
//                        self?.index.send(i)
//                    }
//                }
//            }
//            .store(in: &cancellables)

        let output = viewModel.transform(input: .init(
            collectionScrolledPublisher: index.eraseToAnyPublisher()
        ))

        output.updateShops
            .sink { [weak self] _ in
                guard let self = self else { return }
               
                self.shopCollectionView.reloadData()
                self.updateLayout()
            }
            .store(in: &cancellables)

        output.scrollShop
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print(error) // TODO:
                }
            }, receiveValue: { [weak self] index in
                DispatchQueue.main.async {
                    self?.shopCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
                    self?.index.send(index)
                }

            })
            .store(in: &cancellables)
    }
}

extension SearchResultViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.shops.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShopCollectionViewCell.identifier, for: indexPath) as! ShopCollectionViewCell
        let idx = indexPath.item
        let shop = viewModel.shops[idx]
        if let url = URL(string: shop.photo?.pc?.l ?? "") {
            Nuke.loadImage(with: url, into: cell.imageView)
        }
        cell.setTextInfo(title: shop.name, time: "mock 200m", opening: shop.open)

        return cell
    }

    private func updateLayout() {
        let layout = CarouselCollectionViewFlowLayout()
        let collectionViewSize = shopCollectionView.frame.size
        let cellInsets = UIEdgeInsets(top: 0.0, left: ShopCollectionViewCell.widthInset, bottom: 0.0, right: ShopCollectionViewCell.widthInset)

        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = cellInsets
        let layoutWidth = collectionViewSize.width - ShopCollectionViewCell.widthInset * 2
        let layoutHeight = layoutWidth * ShopCollectionViewCell.cellHeight / ShopCollectionViewCell.cellWidth
        layout.itemSize = CGSize(width: layoutWidth, height: layoutHeight)
        shopCollectionView.collectionViewLayout = layout
    }
}

extension SearchResultViewController: UICollectionViewDelegate, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //セルがタップされた時の処理
        let viewController = R.storyboard.shopDetailViewController().instantiateInitialViewController { [weak self] coder in
            guard let self = self else { return nil }
            return ShopDetailViewController(
                coder: coder,
                shop: self.viewModel.shops[indexPath.item]
            )
        }
        if let viewController = viewController {
            self.present(viewController, animated: true)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)  {
        shouldUpdateIndex()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        shouldUpdateIndex()
    }

    private func shouldUpdateIndex() {
        let x = shopCollectionView.contentOffset.x
        let i = Int(x / (ShopCollectionViewCell.cellWidth + 75)) // TODO: 定数を調整
        if i != index.value {
            index.send(i)
        }
    }
}
