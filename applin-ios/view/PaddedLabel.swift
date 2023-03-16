import Foundation
import UIKit

class PaddedLabel: UIView {
    let label: Label

    init() {
        //self.backgroundColor = pastelGreen
        self.label = Label()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.font = UIFont.preferredFont(forTextStyle: .body)
        self.label.numberOfLines = 0
        self.label.textAlignment = .left
        //self.label.backgroundColor = pastelYellow
        super.init(frame: CGRect.zero)
        print("\(self).init")
        self.addSubview(label)
        // None of these work.  The docs lie:
        // https://developer.apple.com/documentation/uikit/uiview/positioning_content_within_layout_margins
        // container.directionalLayoutMargins =
        //        NSDirectionalEdgeInsets(top: 20.0, leading: 20.0, bottom: 20.0, trailing: 20.0)
        // container.alignmentRectInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
        // container.frame.inset(by: UIEdgeInsets(top: -20.0, left: -20.0, bottom: -20.0, right: -20.0))
        NSLayoutConstraint.activate([
            self.label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8.0),
            self.label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8.0),
            self.label.topAnchor.constraint(equalTo: self.topAnchor, constant: 8.0),
            self.label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8.0),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var description: String {
        "PaddedLabel{\(self.address) \(self.label)}"
    }

    var text: String? {
        set(value) {
            self.label.text = value
        }
        get {
            self.label.text
        }
    }
}

