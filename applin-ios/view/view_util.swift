import Foundation
import UIKit

extension NSLayoutConstraint {
    public func withId(_ id: String) -> Self {
        self.identifier = id
        return self
    }
}
