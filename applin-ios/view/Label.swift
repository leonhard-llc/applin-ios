import Foundation
import UIKit

// https://stackoverflow.com/questions/48211895/how-to-fix-uilabel-intrinsiccontentsize-on-ios-11
// https://stackoverflow.com/questions/17491376/ios-autolayout-multi-line-uilabel/26181894#26181894
// If we use UILabel directly, and we have a Text widget in a TableView, then
// the autolayout picks one of the labels and makes it the maximum width, even if it should be narrow.
// Then on the second layout, it fixes the intrinsic width and displays it the correct width.
// This is a bug in Apple's UILabel class where it sets intrinsicWidth to the max value. XCode View Debugger
// shows the intrinsic width is 65536.  I wasted three hours on this. :(
// A workaround is to set preferredMaxLayoutWidth before updating constraints.
class Label: UILabel {
    override var bounds: CGRect {
        didSet {
            if (bounds.size.width != oldValue.size.width) {
                self.setNeedsUpdateConstraints();
            }
        }
    }

    override func updateConstraints() {
        if (self.preferredMaxLayoutWidth != self.bounds.size.width) {
            self.preferredMaxLayoutWidth = self.bounds.size.width
        }
        super.updateConstraints()
    }
}
