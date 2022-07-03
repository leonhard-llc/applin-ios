import UIKit

class WorkingView: UIViewController {
    init(text: String) {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overCurrentContext
        self.view.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.5)
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        self.view.addSubview(indicator)
        let label = UILabel()
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
        fatalError("init(coder:) has not been implemented")
    }
}
