import Foundation
import UIKit

class Badge: UIView {
    private var label: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        let inset = 4.0
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.textColor = .white
        self.label.font = UIFont.boldSystemFont(ofSize: 16)
        self.label.numberOfLines = 0 // Setting numberOfLines to zero enables wrapping.
        self.label.lineBreakMode = .byCharWrapping
        self.addSubview(self.label)
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
        print("ColumnView.init")
        self.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ text: String, disabled: Bool) {
        self.label.text = text
        if disabled {
            self.backgroundColor = UIColor.placeholderText
        } else {
            self.backgroundColor = UIColor(rgb: 0xE44800)
        }
    }
}
