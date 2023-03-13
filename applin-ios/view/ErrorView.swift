import Foundation
import UIKit

/// Displays some text with a warning icon.
class ErrorView: UIView {
    private let imageView: UIImageView
    private let label: Label

    override init(frame: CGRect) {
        let image = UIImage(systemName: "exclamationmark.circle")
        self.imageView = UIImageView(image: image)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.tintColor = .systemRed

        self.label = Label()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.lineBreakMode = .byWordWrapping
        self.label.numberOfLines = 0

        super.init(frame: frame)
        self.isOpaque = false
        self.addSubview(self.imageView)
        self.addSubview(self.label)
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 4.0),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -4.0),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.12),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            self.label.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 4.0),
            self.label.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -4.0),
            self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.label.leadingAnchor.constraint(equalToSystemSpacingAfter: imageView.trailingAnchor, multiplier: 1.0),
            self.label.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor),
        ])
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setText(_ text: String?) {
        self.label.text = text
    }
}
