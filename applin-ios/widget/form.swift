import Foundation
import UIKit

// TODONT: Don't use UITableView because it cannot update its subviews without causing them to lose keyboard focus.

//         Also, the APIs of UITableView, UITableViewDataSource, and UITableViewDiffableDataSource are extremely hard
//         to use.

struct FormSpec: Equatable, Hashable, ToSpec {
    static let TYP = "form"
    let widgets: [Spec]

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.widgets = try item.optWidgets(config)?.filter({ spec in !spec.is_empty() }) ?? []
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormSpec.TYP)
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        return item
    }

    init(_ widgets: [ToSpec]) {
        self.widgets = widgets.map({ widget in widget.toSpec() })
    }

    func toSpec() -> Spec {
        Spec(.form(self))
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

    func newWidget() -> Widget {
        FormWidget()
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        self.widgets.forEach({ widget in widget.visitActions(f) })
    }
}

class FormWidget: Widget {
    let columnView: ColumnView

    init() {
        print("FormWidget.init()")
        self.columnView = ColumnView()
        self.columnView.translatesAutoresizingMaskIntoConstraints = false
        //self.columnView.backgroundColor = pastelMint
        NSLayoutConstraint.activate([
            self.columnView.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.fittingSizeLevel),
            self.columnView.heightAnchor.constraint(equalToConstant: 0.0).withPriority(.fittingSizeLevel),
        ])
    }

    func getView() -> UIView {
        self.columnView
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case .form = spec.value else {
            throw "Expected .form got: \(spec)"
        }
        self.columnView.update(
                .start,
                separator: .separator,
                spacing: 0.0,
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
