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

    func getView(_: ApplinSession, _: WidgetCache) -> UIView {
        let view = UIView()
        view.backgroundColor = pastelPink
        return view
    }
}
