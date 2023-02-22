import Foundation
import UIKit

struct NavButtonSpec: Equatable, Hashable, ToSpec {
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

    init(pageKey: String, photoUrl: URL? = nil, text: String, subText: String? = nil, _ actions: [ActionSpec]) {
        self.actions = actions
        self.pageKey = pageKey
        self.photoUrl = photoUrl
        self.subText = subText
        self.text = text
    }

    func toSpec() -> Spec {
        Spec(.navButton(self))
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
    private static let INSET: CGFloat = 12.0
    private let constraints = ConstraintSet()
    private var spec: NavButtonSpec
    private var container: TappableView!
    private var imageView: ImageView?
    private var label: UILabel!
    private var subLabel: UILabel?
    private var chevron: UIImageView
    private weak var session: ApplinSession?

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

        self.container.onTap = { [weak self] in
            self?.tap()
        }
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

    func update(_ session: ApplinSession, _ state: ApplinState, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .navButton(navButtonSpec) = spec.value else {
            throw "Expected .navButton got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.spec = navButtonSpec
        self.session = session
        if self.spec.actions.isEmpty {
            self.label.textColor = .placeholderText
            self.chevron.tintColor = .placeholderText
        } else {
            self.label.textColor = .label
            self.chevron.tintColor = .label
        }
        var newConstraints: [NSLayoutConstraint] = []
        if let photoUrl = self.spec.photoUrl {
            if self.imageView == nil {
                self.imageView = ImageView(aspectRatio: 1.0)
                self.container.addSubview(self.imageView!)
            }
            self.imageView!.update(photoUrl, aspectRatio: 1.0, .fit)
        } else {
            if let imageView = self.imageView {
                imageView.removeFromSuperview()
                self.imageView = nil
            }
        }
        if let imageView = self.imageView {
            newConstraints.append(contentsOf: [
                imageView.topAnchor.constraint(equalTo: self.container.topAnchor),
                imageView.leftAnchor.constraint(equalTo: self.container.leftAnchor),
                imageView.widthAnchor.constraint(equalTo: self.container.widthAnchor, multiplier: 0.2),
                imageView.rightAnchor.constraint(lessThanOrEqualTo: self.chevron.leftAnchor),
                imageView.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor),
            ])
        }

        self.label.text = self.spec.text
        if let imageView = self.imageView {
            newConstraints.append(
                    self.label.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: Self.INSET))
        } else {
            newConstraints.append(
                    self.label.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: Self.INSET))
        }
        newConstraints.append(
                self.label.rightAnchor.constraint(lessThanOrEqualTo: self.chevron.leftAnchor, constant: -Self.INSET))
        newConstraints.append(contentsOf: [
            self.label.topAnchor.constraint(greaterThanOrEqualTo: self.container.topAnchor, constant: Self.INSET),
            self.label.centerYAnchor.constraint(equalTo: self.container.centerYAnchor),
            self.label.topAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor, constant: -Self.INSET),
        ])
        self.constraints.set(newConstraints)
    }
}
