import UIKit

class WorkingView: UIView {
    let indicator: UIActivityIndicatorView
    let label: UILabel

    init(text: String) {
        self.indicator = UIActivityIndicatorView()
        self.indicator.translatesAutoresizingMaskIntoConstraints = false
        self.indicator.startAnimating()
        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.text = text
        super.init(frame: CGRect.zero)
        self.addSubview(self.indicator)
        self.addSubview(self.label)
        self.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.5)
        NSLayoutConstraint.activate([
            self.indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.label.topAnchor.constraint(equalToSystemSpacingBelow: self.indicator.bottomAnchor, multiplier: 1.0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }
}
