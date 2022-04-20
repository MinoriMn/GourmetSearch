import UIKit

class ShopCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "ShopCollectionViewCell"

    static let widthInset: CGFloat = 20.0
    static let cellWidth: CGFloat = 295
    static let cellHeight: CGFloat = 330

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var openingLabel: UILabel!
    @IBOutlet private weak var bgView: UIView! {
        didSet {
            bgView.layer.cornerRadius = 16
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public func setTextInfo(title: String?, time: String?, opening: String?) {
        titleLabel.text = title
        timeLabel.text = time
        openingLabel.text = opening
    }

}
