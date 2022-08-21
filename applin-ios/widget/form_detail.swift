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

    func canTap() -> Bool {
        true
    }

    func tap(_ session: ApplinSession, _ cache: WidgetCache) {
        session.doActions(pageKey: self.pageKey, self.actions)
    }

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        return TextData("ERROR: form-detail not in form").getView(session, cache)
    }

    func vars() -> [(String, Var)] {
        []
    }
}
