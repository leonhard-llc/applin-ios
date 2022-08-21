import Foundation
import UIKit

struct EmptyData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "empty"

    func toJsonItem() -> JsonItem {
        let item = JsonItem(EmptyData.TYP)
        return item
    }

    func keys() -> [String] {
        []
    }

    func canTap() -> Bool {
        false
    }

    func tap(_ session: ApplinSession, _ cache: WidgetCache) {
    }

    func getView(_: ApplinSession, _: WidgetCache) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // view.backgroundColor = pastelPink
        return view
    }

    func vars() -> [(String, Var)] {
        []
    }
}
