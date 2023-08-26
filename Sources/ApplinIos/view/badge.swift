import Foundation
import UIKit

class Badge: UIView {
    private var label: Label

    override init(frame: CGRect) {
        let inset = 4.0
        self.label = Label()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.textColor = .white
        self.label.font = UIFont.boldSystemFont(ofSize: 16)
        self.label.numberOfLines = 0 // Setting numberOfLines to zero enables wrapping.
        self.label.lineBreakMode = .byCharWrapping
        super.init(frame: frame)
        self.addSubview(self.label)
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: 0.0).withPriority(.defaultLow),
            self.widthAnchor.constraint(greaterThanOrEqualTo: self.heightAnchor),
            self.heightAnchor.constraint(equalToConstant: 0.0).withPriority(.defaultLow),
            self.label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.label.leftAnchor.constraint(greaterThanOrEqualTo: self.leftAnchor, constant: inset),
            self.label.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor, constant: -inset),
            self.label.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: inset),
            self.label.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -inset),
        ])
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    func update(_ text: String, disabled: Bool) {
        self.label.text = text
        if disabled {
            self.backgroundColor = UIColor.placeholderText
        } else {
            self.backgroundColor = UIColor(rgb: 0xE44800)
        }
    }

    override public var description: String {
        "Badge{\(self.address) \(self.label)}"
    }
}
