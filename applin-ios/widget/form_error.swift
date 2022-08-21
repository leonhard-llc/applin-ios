import UIKit

struct FormErrorData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-error"
    let text: String

    init(_ session: ApplinSession, _ item: JsonItem) throws {
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormErrorData.TYP)
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        []
    }

    func getTapActions() -> [ActionData]? {
        nil
    }

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(systemName: "exclamationmark.circle")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemRed
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = self.text
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        view.addSubview(imageView)
        view.addSubview(label)
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.12),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            label.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalToSystemSpacingAfter: imageView.trailingAnchor, multiplier: 1.0),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
        ])
        return view
    }

    func vars() -> [(String, Var)] {
        []
    }
}
