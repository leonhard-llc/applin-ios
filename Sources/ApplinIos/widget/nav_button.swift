import Foundation
import OSLog
import UIKit

public struct NavButtonSpec: Equatable, Hashable, ToSpec {
    static let TYP = "nav_button"
    let actions: [ActionSpec]
    let badgeText: String?
    let photoUrl: URL?
    let subText: String?
    let text: String

    public init(
            photoUrl: URL? = nil,
            text: String,
            subText: String? = nil,
            badge: String? = nil,
            _ actions: [ActionSpec]
    ) {
        self.actions = actions
        self.badgeText = badge
        self.photoUrl = photoUrl
        self.subText = subText
        self.text = text
    }

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.actions = try item.optActions(config) ?? []
        self.badgeText = item.badge_text
        self.photoUrl = try item.optPhotoUrl(config)
        self.subText = item.sub_text
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(NavButtonSpec.TYP)
        item.actions = self.actions.map({ action in action.toJsonAction() })
        item.badge_text = self.badgeText
        item.photo_url = self.photoUrl?.relativeString
        item.sub_text = self.subText
        item.text = self.text
        return item
    }

    public func toSpec() -> Spec {
        Spec(.navButton(self))
    }

    func keys() -> [String] {
        var keys = ["nav_button:actions:\(self.actions)", "nav_button:text:\(self.text)"]
        if let photoUrl = self.photoUrl {
            keys.append("nav_button:photo:\(photoUrl.absoluteString)")
        }
        if let subText = self.subText {
            keys.append("nav_button:sub_text:\(subText)")
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

    func newWidget(_ ctx: PageContext) -> Widget {
        NavButtonWidget(self, ctx)
    }

    func vars() -> [(String, Var)] {
        []
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        self.actions.forEach(f)
    }
}

class NavButtonWidget: Widget {
    private class OneLabel: UIView {
        private var textLabel: Label!

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.textLabel = Label()
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
            self.init(frame: CGRect.zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not implemented")
        }

        func update(text: String, disabled: Bool) {
            self.textLabel.text = text
            self.textLabel.textColor = disabled ? .placeholderText : .label
        }
    }

    private class TwoLabels: UIView {
        private var textLabel: Label!
        private var subTextLabel: Label!

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.textLabel = Label()
            self.textLabel.translatesAutoresizingMaskIntoConstraints = false
            self.textLabel.numberOfLines = 0 // Setting numberOfLines to zero enables wrapping.
            self.textLabel.lineBreakMode = .byWordWrapping
            self.textLabel.font = UIFont.systemFont(ofSize: 20)
            self.addSubview(self.textLabel)

            self.subTextLabel = Label()
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
            self.init(frame: CGRect.zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not implemented")
        }

        func update(text: String, subText: String, disabled: Bool) {
            self.textLabel.text = text
            self.subTextLabel.text = subText
            self.textLabel.textColor = disabled ? .placeholderText : .label
            self.subTextLabel.textColor = disabled ? .placeholderText : .secondaryLabel
        }
    }

    private enum Labels {
        case oneLabel(OneLabel)
        case twoLabels(TwoLabels)

        func inner() -> UIView {
            switch self {
            case let .oneLabel(label):
                return label
            case let .twoLabels(twoLabels):
                return twoLabels
            }
        }
    }

    private static let SPACING: CGFloat = 12.0
    private static let logger = Logger(subsystem: "Applin", category: "NavButtonWidget")
    private var spec: NavButtonSpec
    private var tappableView: TappableView!
    private var row: RowView!
    private var rowLeftConstraint = ConstraintHolder()
    private var imageView: ImageView?
    private let imageConstraint = ConstraintHolder()
    private var labels: Labels = .oneLabel(OneLabel())
    private var badge: Badge?
    private var chevron: UIImageView
    private let ctx: PageContext

    init(_ spec: NavButtonSpec, _ ctx: PageContext) {
        self.spec = spec
        self.ctx = ctx
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
        Self.logger.dbg("tap")
        Task {
            let _ = await self.ctx.pageStack?.doActions(pageKey: ctx.pageKey, self.spec.actions)
        }
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .navButton(navButtonSpec) = spec.value else {
            throw "Expected .navButton got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.spec = navButtonSpec
        if let photoUrl = self.spec.photoUrl {
            self.imageView = self.imageView ?? ImageView(aspectRatio: 1.0)
            self.imageView!.translatesAutoresizingMaskIntoConstraints = false
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
            case .oneLabel:
                let twoLabels = TwoLabels()
                twoLabels.update(text: self.spec.text, subText: subText, disabled: disabled)
                self.labels = .twoLabels(twoLabels)
            case let .twoLabels(twoLabels):
                twoLabels.update(text: self.spec.text, subText: subText, disabled: disabled)
            }
        } else {
            switch self.labels {
            case let .oneLabel(oneLabel):
                oneLabel.update(text: self.spec.text, disabled: disabled)
            case .twoLabels:
                let label = OneLabel()
                label.update(text: self.spec.text, disabled: disabled)
                self.labels = .oneLabel(label)
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
