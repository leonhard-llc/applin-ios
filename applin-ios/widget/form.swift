import Foundation
import UIKit

// TODONT: Don't use UITableView because it cannot update its subviews without causing them to lose keyboard focus.

//         Also, the APIs of UITableView, UITableViewDataSource, and UITableViewDiffableDataSource are extremely hard
//         to use.

struct FormData: Equatable, Hashable {
    static let TYP = "form"
    let widgets: [Spec]

    init(_ widgets: [Spec]) {
        self.widgets = widgets
    }

    init(_ session: ApplinSession?, pageKey: String, _ item: JsonItem) throws {
        self.widgets = try item.optWidgets(session, pageKey: pageKey) ?? []
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormData.TYP)
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        return item
    }

    func keys() -> [String] {
        []
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [Spec] {
        self.widgets
    }

    func vars() -> [(String, Var)] {
        self.widgets.flatMap({ widget in widget.vars() })
    }

    func widgetClass() -> AnyClass {
        FormWidget.self
    }

    func widget() -> WidgetProto {
        FormWidget()
    }
}

class FormWidget: WidgetProto {
    static let SPACING: Float32 = 4.0
    let columnView: ColumnView

    init() {
        self.columnView = ColumnView()
        self.columnView.translatesAutoresizingMaskIntoConstraints = false
        //self.columnView.backgroundColor = pastelMint
        NSLayoutConstraint.activate([
            self.columnView.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),
            self.columnView.heightAnchor.constraint(equalToConstant: 0.0).withPriority(.defaultLow),
        ])
    }

    func getView() -> UIView {
        self.columnView
    }

    func isFocused() -> Bool {
        false
    }

    func update(_: ApplinSession, _ spec: Spec, _ subs: [WidgetProto]) throws {
        guard case .form = spec.value else {
            throw "Expected .form got: \(spec)"
        }
        self.columnView.update(
                .start,
                separator: .separator,
                spacing: Self.SPACING,
                subviews: subs.map { widget in
                    widget.getView()
                }
        )
    }
}

//private extension UIListContentConfiguration {

//    mutating func addPlaceholderImage(cellWidth: CGFloat) {
//        if let spinnerPath = Bundle.main.path(forResource: "spinner", ofType: "gif") {
//            // TODO: Animate spinner.
//            self.image = UIImage(contentsOfFile: spinnerPath)
//        } else {
//            self.image = UIImage()
//        }
//        let height = cellWidth / 5
//        self.imageProperties.reservedLayoutSize = CGSize(width: height, height: height)
//        self.imageProperties.maximumSize = CGSize(width: height, height: height)
//    }
//
//    mutating func loadImage(_ session: ApplinSession, _ url: URL) async throws {
//        let data = try await session.fetch(url)
//        guard let image = UIImage(data: data) else {
//            throw ApplinError.deserializeError("error loading image from \(url.absoluteString)")
//        }
//        self.image = image
//    }
//}
//
//private class DisclosureImageSubtextCell: UITableViewCell {
//    static let REUSE_ID = "DisclosureImageSubtextCell"
//    var optPhotoUrl: URL?
//
//    func update(_ session: ApplinSession,
//                text: String,
//                subText: String,
//                photoUrl: URL,
//                enabled: Bool
//    ) {
//        self.optPhotoUrl = photoUrl
//        self.accessoryType = .disclosureIndicator
//        var content = self.defaultContentConfiguration()
//        content.text = text
//        content.secondaryText = subText
//        content.textProperties.color = enabled ? .label : .placeholderText
//        content.secondaryTextProperties.color = enabled ? .label : .placeholderText
//        content.addPlaceholderImage(cellWidth: self.bounds.width)
//        self.contentConfiguration = content
//        Task { [content] in
//            var content2 = content
//            try await content2.loadImage(session, photoUrl)
//            DispatchQueue.main.async { [weak self, content2] in
//                if self?.optPhotoUrl == photoUrl {
//                    print("image \(photoUrl)")
//                    self?.contentConfiguration = content2
//                }
//            }
//        }
//    }
//}
