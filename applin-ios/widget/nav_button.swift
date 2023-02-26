import Foundation
import UIKit

struct NavButtonSpec: Equatable, Hashable, ToSpec {
    static let TYP = "nav-button"
    let actions: [ActionSpec]
    let badgeText: String?
    let pageKey: String
    let photoUrl: URL?
    let subText: String?
    let text: String

    init(_ config: ApplinConfig, pageKey: String, _ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.badgeText = item.badgeText
        self.pageKey = pageKey
        self.photoUrl = try item.optPhotoUrl(config)
        self.subText = item.subText
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(NavButtonSpec.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.badgeText = self.badgeText
        item.photoUrl = self.photoUrl?.relativeString
        item.subText = self.subText
        item.text = self.text
        return item
    }

    init(pageKey: String, photoUrl: URL? = nil, text: String, subText: String? = nil, badge: String? = nil, _ actions: [ActionSpec]) {
        self.actions = actions
        self.badgeText = badge
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
    private class Label: UIView {
        private var textLabel: UILabel!

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.textLabel = UILabel()
            self.textLabel.translatesAutoresizingMaskIntoConstraints = false
            self.textLabel.numberOfLines = 0 // Setting numberOfLines to zero enables wrapping.
            self.textLabel.lineBreakMode = .byWordWrapping
            self.textLabel.font = UIFont.systemFont(ofSize: 20)
            self.addSubview(self.textLabel)
            NSLayoutConstraint.activate([
                self.textLabel.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
                self.textLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
                self.textLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
                self.textLabel.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor),
                self.textLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: NavButtonWidget.SPACING),
                self.textLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -NavButtonWidget.SPACING),
            ])
        }

        convenience init() {
            print("Label.init")
            self.init(frame: CGRect.zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(text: String, disabled: Bool) {
            self.textLabel.text = text
            self.textLabel.textColor = disabled ? .placeholderText : .label
        }
    }

    private class TwoLabels: UIView {
        private var textLabel: UILabel!
        private var subTextLabel: UILabel!

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.textLabel = UILabel()
            self.textLabel.translatesAutoresizingMaskIntoConstraints = false
            self.textLabel.numberOfLines = 0 // Setting numberOfLines to zero enables wrapping.
            self.textLabel.lineBreakMode = .byWordWrapping
            self.textLabel.font = UIFont.systemFont(ofSize: 20)
            self.addSubview(self.textLabel)

            self.subTextLabel = UILabel()
            self.subTextLabel.translatesAutoresizingMaskIntoConstraints = false
            self.subTextLabel.font = UIFont.systemFont(ofSize: 16)
            self.subTextLabel.numberOfLines = 0 // Setting numberOfLines to zero enables wrapping.
            self.subTextLabel.lineBreakMode = .byWordWrapping
            self.addSubview(self.subTextLabel)

            NSLayoutConstraint.activate([
                self.textLabel.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
                self.textLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
                self.textLabel.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor),
                self.textLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: NavButtonWidget.SPACING),
                self.textLabel.bottomAnchor.constraint(equalTo: self.subTextLabel.topAnchor),
                self.subTextLabel.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
                self.subTextLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
                self.subTextLabel.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor),
                self.subTextLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -NavButtonWidget.SPACING),
            ])
        }

        convenience init() {
            print("ColumnView.init")
            self.init(frame: CGRect.zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(text: String, subText: String, disabled: Bool) {
            self.textLabel.text = text
            self.subTextLabel.text = subText
            self.textLabel.textColor = disabled ? .placeholderText : .label
            self.subTextLabel.textColor = disabled ? .placeholderText : .secondaryLabel
        }
    }

    private enum Labels {
        case label(Label)
        case twoLabels(TwoLabels)

        func inner() -> UIView {
            switch self {
            case let .label(label):
                return label
            case let .twoLabels(twoLabels):
                return twoLabels
            }
        }
    }

    private static let SPACING: CGFloat = 12.0
    private var spec: NavButtonSpec
    private var tappableView: TappableView!
    private var row: RowView!
    private var rowLeftConstraint = ConstraintHolder()
    private var imageView: ImageView?
    private let imageConstraint = ConstraintHolder()
    private var labels: Labels = .label(Label())
    private var badge: Badge?
    private var chevron: UIImageView
    private weak var session: ApplinSession?

    init(_ spec: NavButtonSpec) {
        print("NavButtonWidget.init(\(spec))")
        self.spec = spec
        self.tappableView = TappableView()
        self.tappableView.translatesAutoresizingMaskIntoConstraints = false
        //self.tappableView.backgroundColor = pastelPeach

        self.row = RowView()
        self.row.translatesAutoresizingMaskIntoConstraints = false
        self.tappableView.addSubview(self.row)

        let chevronImage = UIImage(systemName: "chevron.forward")
        self.chevron = UIImageView(image: chevronImage)

        NSLayoutConstraint.activate([
            self.tappableView.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
            self.row.rightAnchor.constraint(equalTo: self.tappableView.rightAnchor, constant: -Self.SPACING),
            self.row.topAnchor.constraint(equalTo: self.tappableView.topAnchor),
            self.row.bottomAnchor.constraint(equalTo: self.tappableView.bottomAnchor),
            self.chevron.widthAnchor.constraint(equalToConstant: 12.0),
        ])
        self.tappableView.onTap = { [weak self] in
            self?.tap()
        }
    }

    func getView() -> UIView {
        self.tappableView
    }

    func isFocused() -> Bool {
        self.tappableView.isPressed
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
        if let photoUrl = self.spec.photoUrl {
            self.imageView = self.imageView ?? ImageView(aspectRatio: 1.0)
            self.imageConstraint.set(self.imageView!.heightAnchor.constraint(equalToConstant: 60.0))
            self.imageView!.update(photoUrl, aspectRatio: 1.0, .fit)
            self.rowLeftConstraint.set(self.row.leftAnchor.constraint(equalTo: self.tappableView.leftAnchor))
        } else {
            self.imageConstraint.set(nil)
            self.imageView?.removeFromSuperview()
            self.imageView = nil
            self.rowLeftConstraint.set(self.row.leftAnchor.constraint(equalTo: self.tappableView.leftAnchor, constant: Self.SPACING))
        }
        let disabled = self.spec.actions.isEmpty
        if let subText = self.spec.subText, !subText.isEmpty {
            switch self.labels {
            case .label:
                let twoLabels = TwoLabels()
                twoLabels.update(text: self.spec.text, subText: subText, disabled: disabled)
                self.labels = .twoLabels(twoLabels)
            case let .twoLabels(twoLabels):
                twoLabels.update(text: self.spec.text, subText: subText, disabled: disabled)
            }
        } else {
            switch self.labels {
            case let .label(label):
                label.update(text: self.spec.text, disabled: disabled)
            case .twoLabels:
                let label = Label()
                label.update(text: self.spec.text, disabled: disabled)
                self.labels = .label(label)
            }
        }
        if let badgeText = self.spec.badgeText, !badgeText.isEmpty {
            self.badge = self.badge ?? Badge()
            self.badge!.update(badgeText, disabled: disabled)
        } else {
            self.badge = nil
        }
        self.chevron.tintColor = disabled ? .placeholderText : .label
        let subViews = [self.imageView, self.labels.inner(), self.badge, self.chevron].compactMap({ $0 })
        self.row.update(.center, spacing: Float32(Self.SPACING), subviews: subViews)
    }
}
