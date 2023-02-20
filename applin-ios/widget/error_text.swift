import UIKit

struct ErrorTextSpec: Equatable, Hashable, ToSpec {
    static let TYP = "error-text"
    let text: String

    init(_ item: JsonItem) throws {
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ErrorTextSpec.TYP)
        item.text = self.text
        return item
    }

    func toSpec() -> Spec {
        Spec(.errorText(self))
    }

    func keys() -> [String] {
        []
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [Spec] {
        []
    }

    func widgetClass() -> AnyClass {
        ErrorTextWidget.self
    }

    func newWidget() -> Widget {
        ErrorTextWidget(self)
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class ErrorTextWidget: Widget {
    let label: UILabel
    let container: UIView

    init(_ spec: ErrorTextSpec) {
        print("ErrorTextWidget.init(\(spec))")
        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.lineBreakMode = .byWordWrapping
        self.label.numberOfLines = 0

        let image = UIImage(systemName: "exclamationmark.circle")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemRed

        self.container = UIView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        self.container.addSubview(imageView)
        self.container.addSubview(self.label)
        NSLayoutConstraint.activate([
            self.container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: self.container.topAnchor),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.container.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.container.leadingAnchor),
            imageView.widthAnchor.constraint(equalTo: self.container.widthAnchor, multiplier: 0.12),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            self.label.topAnchor.constraint(greaterThanOrEqualTo: self.container.topAnchor),
            self.label.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor),
            self.label.centerYAnchor.constraint(equalTo: self.container.centerYAnchor),
            self.label.leadingAnchor.constraint(equalToSystemSpacingAfter: imageView.trailingAnchor, multiplier: 1.0),
            self.label.trailingAnchor.constraint(lessThanOrEqualTo: self.container.trailingAnchor),
        ])
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ state: ApplinState, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .errorText(errorTextSpec) = spec.value else {
            throw "Expected .errorText got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.label.text = errorTextSpec.text
    }
}
