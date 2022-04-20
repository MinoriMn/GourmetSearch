import Foundation
import UIKit

// 参考: https://qiita.com/abouch/items/2f9cbc0f725c8c7cbb67#%E5%AE%9F%E8%A3%85
final class GridLayoutView: UIView {
    var gridSize: Int = 4
    var borderWidth: CGFloat = 5
    var insets: UIEdgeInsets = .zero

    override func layoutSubviews() {
        super.layoutSubviews()

        let margin = borderWidth

        let width = (bounds.width - CGFloat(gridSize - 1) * margin - insets.left - insets.right) / CGFloat(gridSize)
        let height = (bounds.height - CGFloat(gridSize - 1) * margin - insets.top - insets.bottom) / CGFloat(gridSize)

        let startX: CGFloat = insets.left
        let startY: CGFloat = insets.top

        var x = startX
        var y = startY

        subviews.enumerated().forEach { index, view in
            view.frame.origin = CGPoint(x: x, y: y)
            view.frame.size = CGSize(width: width, height: height)

            x += width + margin
            if index % gridSize == gridSize - 1 {
                x = startX
                y += height + margin
            }
        }
    }
}
