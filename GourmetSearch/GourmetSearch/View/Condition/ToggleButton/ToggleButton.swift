import Foundation
import UIKit
import Combine
import CombineCocoa

class ToggleButton: UIView {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var button: UIButton!

    private var isON: Bool = false

    static func make(name: String, image: UIImage) -> ToggleButton {
        let view = UINib(nibName: "ToggleButton", bundle: nil)
            .instantiate(withOwner: nil, options: nil)
            .first as! ToggleButton

        view.nameLabel.text = name

        view.button.setImage(image, for: .normal)
        view.button.contentHorizontalAlignment = .fill // オリジナルの画像サイズを超えて拡大（水平）
        view.button.contentVerticalAlignment = .fill // オリジナルの画像サイズを超えて拡大(垂直)
        view.button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        return view
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func getButtonTapPublisher() -> AnyPublisher<Void, Never> {
        return button.tapPublisher
    }

    func toggleSwitch() -> Bool {
        self.isON = !self.isON
        setBackgroundColor()
        return isON
    }

    func setSwitch(isON: Bool) -> Bool {
        self.isON = isON
        setBackgroundColor()
        return isON
    }

    private func setBackgroundColor() {
        button.tintColor = isON ? R.color.accentColor() ?? .orange : .lightGray
    }
}
