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
    private var labelsContainer: UIView!
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
        //self.container.backgroundColor = pastelPeach

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

        self.labelsContainer = UIView()
        self.labelsContainer.translatesAutoresizingMaskIntoConstraints = false
        self.container.addSubview(self.labelsContainer)

        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.numberOfLines = 0 // Setting numberOfLines to zero enables word wrap.
        self.label.lineBreakMode = .byWordWrapping
        self.label.font = UIFont.systemFont(ofSize: 20)
        self.labelsContainer.addSubview(self.label)

        self.container.onTap = { [weak self] in
            self?.tap()
        }
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
        var newConstraints: [NSLayoutConstraint] = []
        // Image
        if let photoUrl = self.spec.photoUrl {
            if self.imageView == nil {
                self.imageView = ImageView(aspectRatio: 1.0)
                self.imageView!.translatesAutoresizingMaskIntoConstraints = false
                self.container.addSubview(self.imageView!)
            }
            self.imageView!.update(photoUrl, aspectRatio: 1.0, .fit)
        } else {
            if let imageView = self.imageView {
                imageView.removeFromSuperview()
                self.imageView = nil
            }
        }
        // Label
        self.label.text = self.spec.text
        // Sub-text label
        if let subText = self.spec.subText, !subText.isEmpty {
            if self.subLabel == nil {
                self.subLabel = UILabel()
                self.subLabel!.translatesAutoresizingMaskIntoConstraints = false
                self.subLabel!.font = UIFont.systemFont(ofSize: 16)
                self.subLabel!.numberOfLines = 0 // Setting numberOfLines to zero enables word wrap.
                self.subLabel!.lineBreakMode = .byWordWrapping
                self.labelsContainer.addSubview(self.subLabel!)
            }
            self.subLabel!.text = subText
        } else {
            if let subLabel = self.subLabel {
                subLabel.removeFromSuperview()
                self.subLabel = nil
            }
        }

        // Layout
        if let imageView = self.imageView {
            newConstraints.append(contentsOf: [
                imageView.leftAnchor.constraint(equalTo: self.container.leftAnchor), //.withId("imageView.left"),
                imageView.widthAnchor.constraint(equalTo: self.container.widthAnchor, multiplier: 0.2), //.withId("imageView.width"),
                imageView.topAnchor.constraint(greaterThanOrEqualTo: self.container.topAnchor), //.withId("imageView.top"),
                imageView.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor), //.withId("imageView.bottom"),
                imageView.centerYAnchor.constraint(equalTo: self.container.centerYAnchor), //.withId("imageView.centerY"),
            ])
        }
        newConstraints.append(contentsOf: [
            self.labelsContainer.leftAnchor.constraint(
                    equalTo: self.imageView?.rightAnchor ?? self.container.leftAnchor, constant: Self.INSET), //.withId("labelsContainer.left"),
            self.labelsContainer.rightAnchor.constraint(lessThanOrEqualTo: self.chevron.leftAnchor, constant: -Self.INSET), //.withId("labelsContainer.right"),
            self.labelsContainer.topAnchor.constraint(greaterThanOrEqualTo: self.container.topAnchor, constant: Self.INSET), //.withId("labelsContainer.top"),
            self.labelsContainer.centerYAnchor.constraint(equalTo: self.container.centerYAnchor), //.withId("labelsContainer.centerY"),
            self.labelsContainer.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor, constant: -Self.INSET), //.withId("labelsContainer.bottom"),
        ])
        newConstraints.append(contentsOf: [
            self.label.leftAnchor.constraint(equalTo: self.labelsContainer.leftAnchor), //.withId("label.left"),
            self.label.rightAnchor.constraint(equalTo: self.labelsContainer.rightAnchor), //.withId("label.right"),
            self.label.topAnchor.constraint(equalTo: self.labelsContainer.topAnchor), //.withId("label.top"),
            self.label.bottomAnchor.constraint(equalTo: self.subLabel?.topAnchor ?? self.labelsContainer.bottomAnchor), //.withId("label.bottom"),
        ])
        if let subLabel = self.subLabel {
            newConstraints.append(contentsOf: [
                subLabel.leftAnchor.constraint(equalTo: self.labelsContainer.leftAnchor), //.withId("subLabel.left"),
                subLabel.rightAnchor.constraint(equalTo: self.labelsContainer.rightAnchor), //.withId("subLabel.right"),
                subLabel.bottomAnchor.constraint(equalTo: self.labelsContainer.bottomAnchor), //.withId("subLabel.bottom"),
            ])
        }
        self.constraints.set(newConstraints)
        if self.spec.actions.isEmpty {
            self.label.textColor = .placeholderText
            self.subLabel?.textColor = .placeholderText
            self.chevron.tintColor = .placeholderText
        } else {
            self.label.textColor = .label
            self.subLabel?.textColor = .secondaryLabel
            self.chevron.tintColor = .label
        }
    }
}
