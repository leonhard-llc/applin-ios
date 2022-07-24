import Foundation
import UIKit

struct FormDetailData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-detail"
    let actions: [ActionData]
    let pageKey: String
    let photoUrl: URL?
    let subText: String?
    let text: String

    init(_ session: ApplinSession, pageKey: String, _ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.pageKey = pageKey
        self.photoUrl = try item.optPhotoUrl(session)
        self.subText = item.subText
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormDetailData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.photoUrl = self.photoUrl?.relativeString
        item.subText = self.subText
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        var keys = ["form-detail:actions:\(self.actions)", "form-detail:text:\(self.text)"]
        if let photoUrl = self.photoUrl {
            keys.append("form-detail:photo:\(photoUrl.absoluteString)")
        }
        if let subText = self.subText {
            keys.append("form-detail:sub-text:\(subText)")
        }
        return keys
    }

    func getTapActions() -> [ActionData]? {
        if self.actions.isEmpty {
            return nil
        }
        return self.actions
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        let widget = widgetCache.remove(self.keys()) as? FormDetailWidget ?? FormDetailWidget(self)
        widget.data = self
        widgetCache.putNext(widget)
        return widget.getView(session, widgetCache)
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class FormDetailWidget: WidgetProto {
    var data: FormDetailData
    var button: UIButton!
    weak var session: ApplinSession?

    init(_ data: FormDetailData) {
        print("DetailCellWidget.init(\(data))")
        self.data = data
        let handler = { [weak self] (_: UIAction) in
            print("form-detail UIAction")
            self?.doActions()
        }
        let action = UIAction(title: "uninitialized", handler: handler)
        self.button = UIButton(type: .system, primaryAction: action)
        self.button.translatesAutoresizingMaskIntoConstraints = false
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func doActions() {
        print("form-detail actions")
        self.session?.doActions(pageKey: self.data.pageKey, self.data.actions)
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        self.session = session
        self.button.setTitle("\(self.data.text) 〉", for: .normal)
        self.button.isEnabled = !self.data.actions.isEmpty
        return self.button
    }
}
