import Foundation
import UIKit

class NamedUIView: UIView {
    public var name: String

    init(name: String) {
        self.name = name
        super.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    override public var description: String {
        "\(self.name).{\(self.address)}"
    }
}
