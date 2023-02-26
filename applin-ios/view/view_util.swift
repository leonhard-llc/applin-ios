import Foundation
import UIKit

extension NSLayoutConstraint {
    public func withId(_ id: String) -> Self {
        self.identifier = id
        return self
    }
}

extension UIColor {
    public convenience init(rgb: Int32) {
        let red: UInt8 = UInt8((rgb >> 16) & 0xFF)
        let green: UInt8 = UInt8((rgb >> 8) & 0xFF)
        let blue: UInt8 = UInt8(rgb & 0xFF)
        self.init(red: CGFloat(red) / 256.0, green: CGFloat(green) / 256.0, blue: CGFloat(blue) / 256.0, alpha: 1.0)
    }
}
