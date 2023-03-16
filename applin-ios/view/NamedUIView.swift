import Foundation
import UIKit

class NamedUIView: UIView {
    public var name: String?

    convenience init(name: String) {
        self.init()
        self.name = name
    }

    override public var description: String {
        "\(self.name ?? "NamedUIView"){\(self.address)}"
    }
}
