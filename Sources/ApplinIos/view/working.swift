import UIKit

class WorkingView: UIViewController {
    init(text: String) {
        super.init(nibName: nil, bundle: nil)
        // TODO: Make the page partially transparent.
        // This doesn't work: self.view.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.5)
        self.view.backgroundColor = .secondarySystemBackground
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        self.view.addSubview(indicator)
        let label = Label()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        self.view.addSubview(label)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            label.topAnchor.constraint(equalToSystemSpacingBelow: indicator.bottomAnchor, multiplier: 1.0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }
}
