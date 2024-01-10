import OSLog
import UIKit

class WorkingView: UIView {
    static let logger = Logger(subsystem: "Applin", category: "WorkingView")
    let indicator: UIActivityIndicatorView
    let label: UILabel
    var cancelButton: UIButton?

    init(text: String, _ task: Task<Bool, Error>?) {
        self.indicator = UIActivityIndicatorView()
        self.indicator.translatesAutoresizingMaskIntoConstraints = false
        self.indicator.startAnimating()
        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.text = text
        super.init(frame: CGRect.zero)

        let backAction = UIAction(title: "    Cancel    ", handler: { _ in
            Self.logger.dbg("cancel")
            task?.cancel()
        })
        self.cancelButton = UIButton(type: .system, primaryAction: backAction)
        self.cancelButton!.translatesAutoresizingMaskIntoConstraints = false
        self.cancelButton!.backgroundColor = .secondarySystemBackground
        self.cancelButton!.layer.borderWidth = 2.0
        self.cancelButton!.layer.cornerRadius = 8.0


        self.addSubview(self.indicator)
        self.addSubview(self.label)
        self.addSubview(self.cancelButton!)
        self.isOpaque = false
        self.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.7)
        NSLayoutConstraint.activate([
            self.indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.label.topAnchor.constraint(equalToSystemSpacingBelow: self.indicator.bottomAnchor, multiplier: 1.0),
            self.cancelButton!.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.cancelButton!.topAnchor.constraint(equalToSystemSpacingBelow: self.label.bottomAnchor, multiplier: 1.0),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }
}
