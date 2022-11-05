import Foundation
import UIKit

struct TextData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "text"
    let text: String

    init(_ text: String) {
        self.text = text
    }

    init(_ item: JsonItem) throws {
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(TextData.TYP)
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        ["text:\(self.text)"]
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [WidgetData] {
        []
    }

    func vars() -> [(String, Var)] {
        []
    }

    func widgetClass() -> AnyClass {
        TextWidget.self
    }

    func widget() -> WidgetProto {
        TextWidget()
    }
}

class TextWidget: WidgetProto {
    let label: UILabel
    let container: UIView

    init() {
        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.font = UIFont.preferredFont(forTextStyle: .body)
        self.label.numberOfLines = 0
        self.label.text = ""
        self.label.textAlignment = .left
        label.backgroundColor = pastelYellow
        self.container = UIView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        self.container.addSubview(label)
        // None of these work.  The docs lie:
        // https://developer.apple.com/documentation/uikit/uiview/positioning_content_within_layout_margins
        // container.directionalLayoutMargins =
        //        NSDirectionalEdgeInsets(top: 20.0, leading: 20.0, bottom: 20.0, trailing: 20.0)
        // container.alignmentRectInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
        // container.frame.inset(by: UIEdgeInsets(top: -20.0, left: -20.0, bottom: -20.0, right: -20.0))
        NSLayoutConstraint.activate([
            self.label.leadingAnchor.constraint(equalTo: self.container.leadingAnchor, constant: 8.0),
            self.label.trailingAnchor.constraint(equalTo: self.container.trailingAnchor, constant: -8.0),
            self.label.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 8.0),
            self.label.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -8.0)
        ])
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws {
        guard case let .text(textData) = data else {
            throw "Expected .text got: \(data)"
        }
        self.label.text = textData.text
    }
}
