import Foundation
import UIKit

struct TextSpec: Equatable, Hashable, ToSpec {
    static let TYP = "text"
    let text: String

    init(_ text: String) {
        self.text = text
    }

    init(_ item: JsonItem) throws {
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(TextSpec.TYP)
        item.text = self.text
        return item
    }

    func toSpec() -> Spec {
        Spec(.text(self))
    }

    func keys() -> [String] {
        ["text:\(self.text)"]
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [Spec] {
        []
    }

    func vars() -> [(String, Var)] {
        []
    }

    func widgetClass() -> AnyClass {
        TextWidget.self
    }

    func newWidget() -> Widget {
        TextWidget()
    }
}

// https://stackoverflow.com/questions/48211895/how-to-fix-uilabel-intrinsiccontentsize-on-ios-11
// https://stackoverflow.com/questions/17491376/ios-autolayout-multi-line-uilabel/26181894#26181894
// If we use UILabel directly, and we have a Text widget in a TableView, then
// the autolayout picks one of the labels and makes it the maximum width, even if it should be narrow.
// Then on the second layout, it fixes the intrinsic width and displays it the correct width.
// This is a bug in Apple's UILabel class where it sets intrinsicWidth to the max value. XCode View Debugger
// shows the intrinsic width is 65536.  I wasted three hours on this. :(
// A workaround is to set preferredMaxLayoutWidth before updating constraints.
class UILabelWithIntrinsicSizeFix: UILabel {
    override var bounds: CGRect {
        didSet {
            if (bounds.size.width != oldValue.size.width) {
                self.setNeedsUpdateConstraints();
            }
        }
    }

    override func updateConstraints() {
        if (self.preferredMaxLayoutWidth != self.bounds.size.width) {
            self.preferredMaxLayoutWidth = self.bounds.size.width
        }
        super.updateConstraints()
    }
}

class TextWidget: Widget {
    let container: UIView
    let label: UILabelWithIntrinsicSizeFix

    init() {
        print("TextWidget.init()")
        self.container = UIView()
        self.container.translatesAutoresizingMaskIntoConstraints = false

        self.label = UILabelWithIntrinsicSizeFix()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.font = UIFont.preferredFont(forTextStyle: .body)
        self.label.numberOfLines = 0
        self.label.text = ""
        self.label.textAlignment = .left
        //self.label.backgroundColor = pastelYellow
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
            self.label.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -8.0),
        ])
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ state: ApplinState, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .text(textSpec) = spec.value else {
            throw "Expected .text got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.label.text = textSpec.text
    }
}
