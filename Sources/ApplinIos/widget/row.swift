//import Foundation
//
//struct ApplinRow: Equatable, Hashable {
//    static let TYP = "row"
//    let widgets: [WidgetSpec]
//    let alignment: ApplinVAlignment
//    let spacing: Float32?
//
//    init(_ item: JsonItem, _ session: ApplinSession) throws {
//        self.widgets = try item.optWidgets(session) ?? []
//        self.alignment = item.optAlign() ?? .top
//        self.spacing = item.spacing
//    }
//
//    func toJsonItem() -> JsonItem {
//        let item = JsonItem(ApplinRow.TYP)
//        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
//        item.setAlign(self.alignment)
//        item.spacing = self.spacing
//        return item
//    }
//
////    var body: some View {
////        HStack(alignment: self.alignment, spacing: self.spacing ?? 4.0) {
////            ForEach(self.widgets) { widget in
////                widget
////            }
////        }
////                .border(Color.blue)
////                .padding(1.0)
////    }
//}
