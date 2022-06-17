import Foundation

enum ModalKind: String {
    case alert
    case info
    case question

    public func typ() -> String {
        switch self {
        case .alert:
            return "alert-modal"
        case .info:
            return "info-modal"
        case .question:
            return "question-modal"
        }
    }
}

struct ModalData: Equatable {
    static func ==(lhs: ModalData, rhs: ModalData) -> Bool {
        lhs.title == rhs.title
                && lhs.widgets == rhs.widgets
    }

    let kind: ModalKind
    let typ: String
    let title: String
    let widgets: [WidgetData]

//    @State var isPresented = true

    enum CodingKeys: String, CodingKey {
        // case kind
        case typ
        case title
        case widgets
        // case isPresented
    }

    init(_ kind: ModalKind, title: String, _ widgets: [WidgetData]) {
        self.kind = kind
        self.typ = kind.typ()
        self.title = title
        self.widgets = widgets
    }

    init(_ kind: ModalKind, _ item: JsonItem, _ session: ApplinSession) throws {
        self.kind = kind
        self.typ = kind.typ()
        self.title = try item.requireTitle()
        self.widgets = try item.requireWidgets(session)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(self.kind.typ())
        item.title = self.title
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        return item
    }

    public func add(_ controller: PageData) {
        fatalError("unimplemented")
    }

//    public func toView() -> AnyView {
//        switch self.kind {
//        case .alert:
//            return AnyView(
//                    EmptyView().alert(self.title, isPresented: self.$isPresented) {
//                        ForEach(self.widgets) { widget in
//                            widget
//                        }
//                    }
//            )
//        case .info, .question:
//            return AnyView(
//                    EmptyView().confirmationDialog(self.title, isPresented: self.$isPresented) {
//                        ForEach(self.widgets) { widget in
//                            widget
//                        }
//                    }
//            )
//        }
//    }
}
