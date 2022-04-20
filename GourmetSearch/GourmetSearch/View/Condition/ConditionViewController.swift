import Foundation
import Combine
import CombineCocoa
import UIKit

class ConditionViewController: UIViewController {
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var searchButton: UIButton!
    @IBOutlet private var distanceGesture: UITapGestureRecognizer!
    @IBOutlet private var distanceText: UILabel!
    @IBOutlet private var distanceIcon: UIImageView!
    @IBOutlet private var keywordEditText: UITextField!
    @IBOutlet private var buttonsGridLayout: GridLayoutView!
    private var lunchToggleButton: ToggleButton!
    private var petToggleButton: ToggleButton!
    private var parkingToggleButton: ToggleButton!
    private let distancePickerKeyborad: PickerKeyboard
    private let distanceList: [String] = Range.allCases.map { $0.stringValue() }
    private let distanceSeleced = PassthroughSubject<Int, Never>()

    private let viewModel: ConditionViewModel
    private var cancellables: [AnyCancellable] = []

    init?(coder: NSCoder, initSearchConditionPublisher: AnyPublisher<SearchCondition, Never>, searchConditionPublisher: PassthroughSubject<SearchCondition, Never>) {
        self.viewModel = .init(initSearchConditionPublisher: initSearchConditionPublisher, searchConditionPublisher: searchConditionPublisher)

        self.distancePickerKeyborad = .init(coder: coder, list: distanceList, selected: distanceSeleced)!
        
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let lunchImage = R.image.lunchIcon(),
              let petImage = R.image.dogIcon(),
              let parkingImage = R.image.parkingIcon() else { fatalError() }

        self.lunchToggleButton = .make(name: "ランチあり", image: lunchImage)
        self.petToggleButton = .make(name: "ペット可", image: petImage)
        self.parkingToggleButton = .make(name: "駐車場あり", image: parkingImage)


        buttonsGridLayout.gridSize = 4
        buttonsGridLayout.addSubview(lunchToggleButton)
        buttonsGridLayout.addSubview(petToggleButton)
        buttonsGridLayout.addSubview(parkingToggleButton)
        buttonsGridLayout.backgroundColor = .white

        distanceGesture.tapPublisher
            .sink { [weak self] _ in
                self?.distancePickerKeyborad.becomeFirstResponder()
            }
            .store(in: &cancellables)
        distancePickerKeyborad.frame = CGRect(x: 10, y: UIScreen.main.bounds.size.height - 40, width: UIScreen.main.bounds.size.width - 20, height: 40)
        self.view.addSubview(distancePickerKeyborad)

        bind(to: viewModel)
    }

    private func bind(to viewModel: ConditionViewModel) {
        let distanceSelected = distanceSeleced
            .map { [weak self] row -> Range in
                self?.distanceText.text = self?.distanceList[row]
                print(row)
                let range = Range(rawValue: row + 1) ?? .u1000m
                self?.setDistanceImage(range: range)
                return range
            }
            .eraseToAnyPublisher()

        let lunchButtonTapped = lunchToggleButton.getButtonTapPublisher()
            .map { [weak self] _ -> Bool in
                return self?.lunchToggleButton.toggleSwitch() ?? false
            }
            .eraseToAnyPublisher()

        let petButtonTapped = petToggleButton.getButtonTapPublisher()
            .map { [weak self] _ -> Bool in
                return self?.petToggleButton.toggleSwitch() ?? false
            }
            .eraseToAnyPublisher()

        let parkingButtonTapped = parkingToggleButton.getButtonTapPublisher()
            .map { [weak self] _ -> Bool in
                return self?.parkingToggleButton.toggleSwitch() ?? false
            }
            .eraseToAnyPublisher()

        let output = viewModel.transform(
            input: .init(
                distanceSelected: distanceSelected,
                keywordChanged: keywordEditText.textPublisher,
                lunchButtonTapped: lunchButtonTapped,
                petButtonTapped: petButtonTapped,
                parkingButtonTapped: parkingButtonTapped,
                cancelButtonTapped: cancelButton.tapPublisher,
                searchButtonTapped: searchButton.tapPublisher
            )
        )

        output.setSearchCondition
            .sink { [weak self] searchCondition in
                self?.distanceText.text = self?.distanceList[searchCondition.range.rawValue - 1]
                self?.setDistanceImage(range: searchCondition.range)
                self?.keywordEditText.text = searchCondition.keyword
                self?.lunchToggleButton.setSwitch(isON: searchCondition.isLunch)
                self?.petToggleButton.setSwitch(isON: searchCondition.isPet)
                self?.parkingToggleButton.setSwitch(isON: searchCondition.isParking)
            }
            .store(in: &cancellables)

        output.close
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)
    }

    private func setDistanceImage(range: Range) {
        var image: UIImage? = nil
        switch range {
        case .u300m, .u500m:
            image = R.image.walkIcon()
        case .u1000m, .u2000m:
            image = R.image.cycleIcon()
        case .u3000m:
            image = R.image.carIcon()
        }
        self.distanceIcon.image = image
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
