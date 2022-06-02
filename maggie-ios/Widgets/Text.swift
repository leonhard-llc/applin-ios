import Foundation
import UIKit

struct MaggieText: Equatable, Hashable {
    static let TYP = "text"
    let text: String

    init(_ text: String) {
        self.text = text
    }

    init(_ item: JsonItem) throws {
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieText.TYP)
        item.text = self.text
        return item
    }

    func makeView() -> UIView {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.text = self.text
        label.textAlignment = .left
        label.backgroundColor = pastelYellow
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        // None of these work.  The docs lie:
        // https://developer.apple.com/documentation/uikit/uiview/positioning_content_within_layout_margins
        // container.directionalLayoutMargins =
        //        NSDirectionalEdgeInsets(top: 20.0, leading: 20.0, bottom: 20.0, trailing: 20.0)
        // container.alignmentRectInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
        // container.frame.inset(by: UIEdgeInsets(top: -20.0, left: -20.0, bottom: -20.0, right: -20.0))
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8.0),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8.0),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8.0),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8.0)
        ])
        return container
    }
}
