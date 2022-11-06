import Foundation
import UIKit

/// A view that changes its background to `backgroundColorOnTouch` when touched.
class TappableView: UIView {
    var backgroundColorOnTouch: UIColor?
    var isPressed = false
    var onTap: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("TouchShowingView.touchesBegan")
        super.touchesBegan(touches, with: event)
        self.backgroundColor = self.backgroundColorOnTouch
        self.isPressed = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("TouchShowingView.touchesEnded")
        super.touchesEnded(touches, with: event)
        self.backgroundColor = nil
        self.isPressed = false
        if let onTap = self.onTap {
            onTap()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("TouchShowingView.touchesCancelled")
        super.touchesEnded(touches, with: event)
        self.backgroundColor = nil
        self.isPressed = false
    }
}
