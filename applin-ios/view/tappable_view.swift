import Foundation
import UIKit

/// A view that changes its background to `backgroundColorOnTouch` when touched.
class TappableView: UIView {
    var isPressed = false
    var onTap: (() -> Void)?
    private var originalBackgroundColor: UIColor?

    public override var description: String {
        "TappableView{frame=\(self.frame), subviews=\(self.subviews)}"
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("TouchShowingView.touchesBegan")
        super.touchesBegan(touches, with: event)
        self.originalBackgroundColor = self.backgroundColor
        self.backgroundColor = .systemGray6
        self.isPressed = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("TouchShowingView.touchesEnded")
        super.touchesEnded(touches, with: event)
        self.backgroundColor = self.originalBackgroundColor
        self.isPressed = false
        if let onTap = self.onTap {
            onTap()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("TouchShowingView.touchesCancelled")
        super.touchesEnded(touches, with: event)
        self.backgroundColor = self.originalBackgroundColor
        self.isPressed = false
    }
}
