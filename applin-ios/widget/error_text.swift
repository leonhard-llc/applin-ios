import UIKit

struct ErrorTextData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "error-text"
    let text: String

    init(_ item: JsonItem) throws {
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ErrorTextData.TYP)
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        []
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [WidgetData] {
        []
    }

    func widgetClass() -> AnyClass {
        ErrorTextWidget.self
    }

    func widget() -> WidgetProto {
        ErrorTextWidget(self)
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class ErrorTextWidget: WidgetProto {
    let label: UILabel
    let container: UIView

    init(_ data: ErrorTextData) {
        print("ErrorTextWidget.init()")
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

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws {
        guard case let .errorText(errorData) = data else {
            throw "Expected .errorText got: \(data)"
        }
        self.label.text = errorData.text
    }
}
