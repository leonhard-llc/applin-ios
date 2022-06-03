import Foundation
import UIKit

class PlainPageController: UIViewController {
    weak var session: MaggieSession?
    var page: MaggiePlainPage
    var subView: UIView = UIView()
    var constraints: [NSLayoutConstraint] = []

    init(_ session: MaggieSession, _ page: MaggiePlainPage) {
        self.session = session
        self.page = page
        super.init(nibName: nil, bundle: nil)
        self.update()
    }

    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }

    func setPage(_ page: MaggiePlainPage) {
        if page == self.page {
            return
        }
        self.page = page
        self.update()
    }

    func update() {
        if let session = self.session {
            self.title = page.title
            self.view.backgroundColor = .systemBackground
            // self.navigationItem.navBarHidden // <--- This would make everything easy, Apple didn't add it.
            NSLayoutConstraint.deactivate(self.constraints)
            self.constraints.removeAll(keepingCapacity: true)
            self.subView.removeFromSuperview()
            self.subView = self.page.widget.makeView(session)
            self.view.addSubview(self.subView)
            self.constraints.append(
                    self.subView.topAnchor.constraint(
                            equalTo: self.view.safeAreaLayoutGuide.topAnchor))
            self.constraints.append(
                    self.subView.bottomAnchor.constraint(
                            lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor))
            self.constraints.append(
                    self.subView.leadingAnchor.constraint(
                            equalTo: self.view.safeAreaLayoutGuide.leadingAnchor))
            self.constraints.append(
                    self.subView.trailingAnchor.constraint(
                            lessThanOrEqualTo: self.view.safeAreaLayoutGuide.trailingAnchor))
            NSLayoutConstraint.activate(self.constraints)
        }
    }
}

struct MaggiePlainPage: Equatable {
    static let TYP = "plain-page"
    let title: String?
    let widget: MaggieWidget

    init(title: String?, _ widget: MaggieWidget) {
        self.title = title
        self.widget = widget
    }

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.title = item.title
        self.widget = try item.requireWidget(session)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieNavPage.TYP)
        item.title = self.title
        item.widget = self.widget.toJsonItem()
        return item
    }

    public func allowBackSwipe() -> Bool {
        false
    }
}
