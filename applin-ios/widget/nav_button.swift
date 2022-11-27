import Foundation
import UIKit

struct NavButtonSpec: Equatable, Hashable {
    static let TYP = "nav-button"
    let actions: [ActionSpec]
    let pageKey: String
    let photoUrl: URL?
    let subText: String?
    let text: String

    init(_ config: ApplinConfig, pageKey: String, _ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.pageKey = pageKey
        self.photoUrl = try item.optPhotoUrl(config)
        self.subText = item.subText
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(NavButtonSpec.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.photoUrl = self.photoUrl?.relativeString
        item.subText = self.subText
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        var keys = ["nav-button:actions:\(self.actions)", "nav-button:text:\(self.text)"]
        if let photoUrl = self.photoUrl {
            keys.append("nav-button:photo:\(photoUrl.absoluteString)")
        }
        if let subText = self.subText {
            keys.append("nav-button:sub-text:\(subText)")
        }
        return keys
    }

    func priority() -> WidgetPriority {
        .focusable
    }

    func subs() -> [Spec] {
        []
    }

    func widgetClass() -> AnyClass {
        NavButtonWidget.self
    }

    func newWidget() -> Widget {
        NavButtonWidget(self)
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class NavButtonWidget: Widget {
    static let INSET: CGFloat = 12.0
    let constraints = ConstraintSet()
    var spec: NavButtonSpec
    var container: TappableView!
    var image: UIImageView?
    var label: UILabel!
    var subLabel: UILabel?
    var chevron: UIImageView
    weak var session: ApplinSession?

    init(_ spec: NavButtonSpec) {
        print("NavButtonWidget.init(\(spec))")
        self.spec = spec
        self.container = TappableView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
        ])

        let chevronImage = UIImage(systemName: "chevron.forward")
        self.chevron = UIImageView(image: chevronImage)
        self.chevron.translatesAutoresizingMaskIntoConstraints = false
        self.chevron.tintColor = .label
        self.container.addSubview(self.chevron)
        NSLayoutConstraint.activate([
            self.chevron.widthAnchor.constraint(equalToConstant: 12.0),
            self.chevron.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -Self.INSET),
            self.chevron.centerYAnchor.constraint(equalTo: self.container.centerYAnchor),
            self.chevron.topAnchor.constraint(greaterThanOrEqualTo: self.container.topAnchor, constant: Self.INSET),
            self.chevron.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor, constant: -Self.INSET),
        ])

        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.container.addSubview(self.label)
        NSLayoutConstraint.activate([
            self.label.topAnchor.constraint(greaterThanOrEqualTo: self.container.topAnchor, constant: Self.INSET),
            self.label.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor, constant: -Self.INSET),
            self.label.leftAnchor.constraint(greaterThanOrEqualTo: self.container.leftAnchor, constant: Self.INSET),
            self.label.rightAnchor.constraint(lessThanOrEqualTo: self.chevron.leftAnchor, constant: -Self.INSET),
        ])
        self.container.onTap = { [weak self] in
            self?.tap()
        }
        // TODO: Support image.
        // TODO: Support sub-text.
        // TODO: Support badge and number badge.
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        self.container.isPressed
    }

    @objc func tap() {
        print("NavButtonWidget.tap")
        self.session?.doActions(pageKey: self.spec.pageKey, self.spec.actions)
    }

    func update(_ session: ApplinSession, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .navButton(navButtonSpec) = spec.value else {
            throw "Expected .navButton got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.spec = navButtonSpec
        self.session = session
        self.label.text = self.spec.text
        self.constraints.set([
            self.label.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: Self.INSET),
            self.label.rightAnchor.constraint(lessThanOrEqualTo: self.chevron.leftAnchor, constant: -Self.INSET),
            self.label.centerYAnchor.constraint(equalTo: self.container.centerYAnchor),
        ])
    }
}
