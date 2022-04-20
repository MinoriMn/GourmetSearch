import Foundation
import UIKit
import Combine
import CombineCocoa

class SearchBar: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView! {
        didSet {
            backgroundView.layer.cornerRadius = 16.0
        }
    }
    @IBOutlet weak var conditionButton: UIButton! {
        didSet {
            backgroundView.layer.cornerRadius = 16.0
        }
    }

    static func make(condition: String) -> SearchBar {
        let view = UINib(nibName: "SearchBar", bundle: nil)
            .instantiate(withOwner: nil, options: nil)
            .first as! SearchBar

        view.conditionButton.titleLabel?.text = condition

        return view
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setCondition(condition: String) {
        conditionButton.setTitle(condition, for: .normal)
    }

    func getConditionButtonTapPublisher() -> AnyPublisher<Void, Never> {
        return conditionButton.tapPublisher
    }
}
